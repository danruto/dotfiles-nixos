{ pkgs, pkgs-unstable, pkgs-master, fff, lib, config, ... }:
let
  # Standalone home (e.g. orb-arch via `make hm/switch`) skips Pi: its install
  # activation shells out to a global npm install that fails on read-only/Nix
  # store setups, and Pi isn't wanted on that profile anyway.
  # piEnabled = platform != "standalone";
  piEnabled = true;

  fff-mcp = fff.packages.${pkgs.stdenv.hostPlatform.system}.default;
  lazypi = pkgs.callPackage ./lazypi.nix { };
  dsh = pkgs-unstable.callPackage ./dsh.nix { };
  command-code = pkgs-unstable.callPackage ./command-code.nix { };

  claude-code = pkgs-master.claude-code.override {
    manifest = {
      version = "2.1.258";
      platforms = {
        "darwin-arm64".checksum = "b63136194160791c27cfa7b0403060d85eb0752991625fde8c09f9acacb17c78";
        "darwin-x64".checksum = "c857db5cd712865623bd61e806cf3f7e8e279c9e5c7c0af5eca06ca6717fc7fb";
        "linux-arm64".checksum = "43dc490af55262edcb3e9b1cb315de22cc09ccb08bd52a4c39bc5eabaa63100f";
        "linux-x64".checksum = "704f1334ac65d3e89e1c6c1d7663293ad786a6166afdb71b5075337df630f976";
      };
    };
  };

  # nixpkgs builds tokscale from Rust source, which takes far too long. Upstream
  # publishes the same release as prebuilt per-platform binaries on npm, so pull
  # those instead. Bumping means a new version + four integrity hashes from
  # `npm view @tokscale/cli-<plat> dist.integrity`.
  tokscale =
    let
      version = "4.15.0";
      sources = {
        "x86_64-linux" = { plat = "linux-x64-gnu"; hash = "sha512-sqoiUSbfPdbEOQASuj2Ovi1/637YIFxxffrvpVmzR4yvON/HUoAbYPnp8hOGH0EtTSPE3wJJ4aE62UR5hA8c9A=="; };
        "aarch64-linux" = { plat = "linux-arm64-gnu"; hash = "sha512-V3XTh2eQoJ/bB3XBYHGhmJxTSHyyGwPi9d4Lqszr8M/mKXlHUu2hOqwWmhl6UhbmZciWyIUJTl7C75eKd09YRg=="; };
        "x86_64-darwin" = { plat = "darwin-x64"; hash = "sha512-EP7m6dT3ZPxmFlXdged56uTrJ19Y4By663nj4WO9X/rEj6CAM+s+YCPh82RW4X4X1UmfiKST2H/G9ULbCobEJA=="; };
        "aarch64-darwin" = { plat = "darwin-arm64"; hash = "sha512-9YlcvprlplFIU6ZmNH+/O6MkcFiGjRHm1b8ztNkNwfy/GlE2OwuagVhj3lpWAO5FNMkDRePJqPZA+MeQ6ucPQw=="; };
      };
      target = sources.${pkgs.stdenv.hostPlatform.system};
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "tokscale";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@tokscale/cli-${target.plat}/-/cli-${target.plat}-${version}.tgz";
        inherit (target) hash;
      };
      nativeBuildInputs = pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.autoPatchelfHook;
      installPhase = "install -Dm755 bin/tokscale $out/bin/tokscale";
      meta = {
        description = "Track token usage across AI coding agents from your terminal";
        homepage = "https://github.com/junhoyeo/tokscale";
        license = pkgs.lib.licenses.mit;
        platforms = builtins.attrNames sources;
        mainProgram = "tokscale";
      };
    };

  # nixpkgs-master lags upstream pi releases, so version/src/hashes are pinned
  # here too. Drop the version, src, npmDepsHash and modelData overrides (keep
  # postFixup) once nixpkgs-master ships this version or newer.
  pi-coding-agent = pkgs-master.pi-coding-agent.overrideAttrs (final: _: {
    version = "0.84.4";
    src = pkgs-master.fetchFromGitHub {
      owner = "earendil-works";
      repo = "pi";
      tag = "v${final.version}";
      hash = "sha256-7z8OXao1PzmBEepDkIqVqyfQBPHulBlKcGymDYsnMvc=";
    };
    # npmDeps must be overridden directly, not via npmDepsHash: buildNpmPackage
    # bakes the resolved npmDeps into the derivation attrs, so on overrideAttrs
    # the hash argument is ignored and the old lockfile cache would be reused.
    npmDeps = pkgs-master.fetchNpmDeps {
      inherit (final) src;
      name = "pi-coding-agent-${final.version}-npm-deps";
      hash = "sha256-35GC3Q4Jf4URvqoEYHeM63x49tTmrth62//PvKm4I7Q=";
      fetcherVersion = 1;
    };
    # Hydrated model catalog; gitignored upstream, see nixpkgs' package.nix.
    modelData = pkgs-master.fetchurl {
      url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${final.version}.tgz";
      hash = "sha256-39PJKc7lpzhxmaCiTfwb4glvHqj1n/uChRmKDtAev5M=";
    };

    # pi spawns `npm install` at runtime for package extensions and compiles
    # native npm modules (e.g. node-pty) when installing/updating them;
    # node-gyp needs python on PATH. Scope these to pi's own wrapper instead
    # of the global profile (gcc/gnumake come from user/lang/cc). This
    # replaces the upstream wrapper, so re-add its ripgrep/fd and env defaults.
    postFixup = ''
      wrapProgram $out/bin/pi \
        --prefix PATH : ${lib.makeBinPath (with pkgs-master; [ nodejs ripgrep fd python3 ])} \
        --set-default PI_SKIP_VERSION_CHECK 1 \
        --set-default PI_TELEMETRY 0
    '';
  });

  # Rust TUI coding agent (https://github.com/1jehuang/jcode). Not in nixpkgs
  # and upstream ships no nix expr, so build the `jcode` bin from the release
  # tag. The workspace also declares dev/bench bins, hence the explicit
  # --bin jcode.
  jcode =
    let
      version = "0.81.4";
      src = pkgs-unstable.fetchFromGitHub {
        owner = "1jehuang";
        repo = "jcode";
        tag = "v${version}";
        hash = "sha256-wdTod5iEcpLqQ1mTdYBtyovxEo4NUa/Hv9mIPXvGeWk=";
      };
    in
    pkgs-unstable.rustPlatform.buildRustPackage {
      pname = "jcode";
      inherit version src;
      cargoHash = "sha256-BQZG31o0WInz5QC1R8yJNmQRYb6x4ylMHI1i3l+FA8k=";
      cargoBuildFlags = [ "--bin" "jcode" ];
      nativeBuildInputs = [ pkgs-unstable.pkg-config ];
      buildInputs = [ pkgs-unstable.openssl ];
      doCheck = false;
      meta = {
        description = "RAM-efficient multi-model TUI coding agent";
        homepage = "https://github.com/1jehuang/jcode";
        license = pkgs.lib.licenses.mit;
        mainProgram = "jcode";
      };
    };

  # opencode v2 (the `beta`/`dev` channel). v2 lives on an untagged dev branch
  # with a rewritten layout (packages/cli, not packages/opencode), so the
  # nixpkgs 1.x source build (a *different*, v1 package) doesn't apply —
  # install upstream's own prebuilt bun binary from npm instead. This pins one
  # dated snapshot: it does NOT track the channel, bumping means a new
  # timestamp version + four hashes. The npm dist-tag prefix switched from
  # `beta-` to `dev-` around 2026-08-12; check both when bumping. Drop this
  # whole thing once v2 ships tagged releases and lands in nixpkgs.
  opencode-beta =
    let
      version = "0.0.0-dev-202609010712";
      hashes = {
        "x86_64-linux" = { plat = "linux-x64"; hash = "sha512-wA/N6noNIYUh6VCQHrYGvhY/vcpKilGCOAzmwqhXDdk4i1J7hF1IKbB17oJ3tdISk9scno8XS4Ah1D0DucIcOA=="; };
        "aarch64-linux" = { plat = "linux-arm64"; hash = "sha512-O0bcRnOcjwyJSsnjG6qbVZGlLj9qpWaOXukuqjC8AEQIP3fxGxzU1Y6lXbg8eTOSjB67qsk6cGzP7lYWmyA8KQ=="; };
        "x86_64-darwin" = { plat = "darwin-x64"; hash = "sha512-hh2hwlN+nD4/qV4dW7SNEP0aRQ1AWC/Gmdo9huITF+rhSjP3vnAka5IoytmafHBGsKVFqxa3sd1ee+luS8Lw3w=="; };
        "aarch64-darwin" = { plat = "darwin-arm64"; hash = "sha512-W+JLFY8wXa2Cl7dcAPrng3qFPfeB5Mc8mpj8tkqK4BiNP+dNqLJbDVtp1cXrdLAt9pKZ9ENZO9h7UPP9Vpkrpg=="; };
      };
      target = hashes.${pkgs.stdenv.hostPlatform.system};
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "opencode";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/opencode-${target.plat}/-/opencode-${target.plat}-${version}.tgz";
        inherit (target) hash;
      };
      nativeBuildInputs = [ pkgs.makeBinaryWrapper ]
        ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.autoPatchelfHook;
      installPhase = ''
        runHook preInstall
        install -Dm755 bin/opencode $out/bin/opencode
        wrapProgram $out/bin/opencode \
          --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep ]} \
          --set OPENCODE_DISABLE_AUTOUPDATE true
        runHook postInstall
      '';
      # bun --compile binary: the JS payload is appended to the ELF, stripping
      # it corrupts the executable (nixpkgs' own opencode does the same).
      dontStrip = true;
      meta = {
        description = "AI coding agent built for the terminal (v2 beta/dev channel)";
        homepage = "https://github.com/anomalyco/opencode";
        platforms = builtins.attrNames hashes;
        mainProgram = "opencode";
      };
    };

  revdiff =
    let
      version = "1.12.0";
      sources = {
        "x86_64-linux" = { suffix = "linux_amd64"; hash = "sha256-OzZHjDudbG9VV1Ff7YduiM4cPRRWRxSj7VrvuQPMcVQ="; };
        "aarch64-linux" = { suffix = "linux_arm64"; hash = "sha256-V6t+VbfVufDNA5NZRtMzpm3cT9Tv4Bm5h+GFpy/DVOE="; };
        "x86_64-darwin" = { suffix = "darwin_amd64"; hash = "sha256-U0qrpuGOSJxUWiAquNayRtAJZHiwBJClLmxUcWUFQ4g="; };
        "aarch64-darwin" = { suffix = "darwin_arm64"; hash = "sha256-nWyoQLmMZID8HjmAOmOF9JtjidKMnrRtog+U861pHWg="; };
      };
      target = sources.${pkgs.stdenv.hostPlatform.system};
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "revdiff";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://github.com/umputun/revdiff/releases/download/v${version}/revdiff_${version}_${target.suffix}.tar.gz";
        inherit (target) hash;
      };
      nativeBuildInputs = pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.autoPatchelfHook;
      sourceRoot = ".";
      installPhase = ''
        runHook preInstall
        install -Dm755 revdiff $out/bin/revdiff
        runHook postInstall
      '';
      meta = {
        description = "TUI for reviewing diffs, files, and documents with inline annotations";
        homepage = "https://revdiff.com";
        platforms = builtins.attrNames sources;
      };
    };

  aiConfigs = "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs";

  # Both Claude Code subscriptions share one config set: ~/.claude (default) and
  # ~/.claude-healix (selected with CLAUDE_CONFIG_DIR).
  claudeDirs = [ ".claude" ".claude-healix" ];
in
{
  home.packages = (with pkgs-unstable; [
    # opencode
    sox # voice for cc
    revdiff
    jcode
    # amp-cli
    # gemini-cli
    # codex
    # nur.repos.charmbracelet.crush
  ]) ++ [
    dsh
    tokscale
    command-code
    claude-code
    opencode-beta
    pkgs-master.codex
    fff-mcp # on PATH so Claude/Pi MCP configs can reference `fff-mcp` by name
  ] ++ lib.optionals piEnabled [
    pi-coding-agent
    lazypi
  ];

  # CLAUDE.md, the statusline scripts and settings.json are out-of-store symlinks
  # to the live working tree (like herdr's config.toml) so edits — including
  # Claude Code's own writes to settings.json — land directly in this repo
  # without a redeploy. Both subscription dirs in `claudeDirs` get the same set,
  # so there is nothing to hand-copy between them. Assumes the repo is checked
  # out at ~/dotfiles-nixos. fff-mcp is on PATH (see home.packages) so the static
  # Claude/OMP MCP configs can reference it by bare name instead of a store path.
  #
  # NOTE: Claude Code does NOT read `mcpServers` from settings.json — the key is
  # not in the settings schema and is silently ignored. MCP servers only load
  # from ~/.claude.json or a repo's .mcp.json. ~/.claude.json is mutable state
  # this flake does not manage, so on a fresh machine register fff manually:
  #     claude mcp add --scope user fff fff-mcp
  # Verify with `claude mcp list` (expect "fff: fff-mcp - ✔ Connected").
  # Pi's MCP config is unaffected and still reads its own settings file.
  home.file = (lib.foldl' lib.mergeAttrs { } (map
    (dir: {
      "${dir}/CLAUDE.md".source =
        config.lib.file.mkOutOfStoreSymlink "${aiConfigs}/CLAUDE.md";
      "${dir}/statusline.sh".source =
        config.lib.file.mkOutOfStoreSymlink "${aiConfigs}/statusline.sh";
      "${dir}/subagent-statusline.sh".source =
        config.lib.file.mkOutOfStoreSymlink "${aiConfigs}/subagent-statusline.sh";
    })
    claudeDirs)) // {
    # Non-Claude harnesses read their own global-instructions filename; point
    # both at the same canonical file so every agent gets identical rules.
    # opencode's global precedence makes ~/.config/opencode/AGENTS.md win over
    # the ~/.claude/CLAUDE.md fallback (first match wins), so this replaces —
    # not duplicates — that fallback.
    ".config/opencode/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${aiConfigs}/CLAUDE.md";
  } // lib.optionalAttrs piEnabled {
    ".pi/agent/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${aiConfigs}/CLAUDE.md";
  };

  # settings.json can't go through home.file/mkOutOfStoreSymlink: that routes the
  # link through the read-only home-manager-files store dir, and Claude Code
  # rewrites settings.json atomically (write a sibling .tmp, then rename). It
  # resolves only the first symlink hop, so the .tmp lands in /nix/store → EROFS
  # (breaks plugin installs, /config, etc.). Create a *direct* out-of-store
  # symlink to the live repo file instead, so the sibling .tmp lands in the
  # writable repo dir and Claude's own edits still sync straight back into git.
  #
  # rename() replaces the symlink itself, so an in-place rewrite can still leave a
  # detached regular file behind (this happened to ~/.claude/settings.json). The
  # loop below heals that: a non-symlink target newer than the repo file is copied
  # back into the repo first — never discarded — then re-linked.
  home.activation.claudeSettingsLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="${aiConfigs}/settings.json"
    for dir in ${lib.concatMapStringsSep " " (d: ''"${config.home.homeDirectory}/${d}"'') claudeDirs}; do
      target="$dir/settings.json"
      run mkdir -p "$dir"
      if [ -f "$target" ] && [ ! -L "$target" ]; then
        if [ "$target" -nt "$settings" ]; then
          run cp -f "$target" "$settings"
        fi
        run rm -f "$target"
      fi
      run ln -sfn "$settings" "$target"
    done
  '';

  # opencode rewrites its global config in place (it injects "$schema" when
  # missing), so use a direct out-of-store symlink for the same reason as
  # Claude's settings above. The repo file already sets $schema, so no rewrite
  # should happen, but the direct link keeps writes inside the repo either way.
  home.activation.opencodeConfigLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.home.homeDirectory}/.config/opencode"
    run ln -sf "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/opencode.json" \
      "${config.home.homeDirectory}/.config/opencode/opencode.json"
  '';

  # Pi rewrites settings.json atomically, so use direct out-of-store symlinks
  # for the same reason as Claude's settings above. Pi's own settings changes
  # then land in this repo, while listed packages install on the next launch.
  home.activation.piConfigLinks = lib.mkIf piEnabled (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.home.homeDirectory}/.pi/agent/extensions"
    run ln -sfn "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/pi-settings.json" \
      "${config.home.homeDirectory}/.pi/agent/settings.json"
    run ln -sfn "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/pi-models.json" \
      "${config.home.homeDirectory}/.pi/agent/models.json"
    run ln -sfn "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/pi-usage-status.ts" \
      "${config.home.homeDirectory}/.pi/agent/extensions/pi-usage-status.ts"
  '');

  # Command Code's global taste (~/.commandcode/taste) is a writable tree that
  # the learning system rewrites in place, so use a direct out-of-store symlink
  # (same rationale as Claude's settings above) pointing at the tracked copy in
  # this repo. Project-level .commandcode/ stays gitignored. rm + ln (instead of
  # ln -sfn alone) so a pre-existing real dir — e.g. one created by an older
  # command-code version before this link existed — gets replaced rather than
  # linked into.
  home.activation.commandcodeTasteLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    tasteRepo="${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/taste"
    tasteTarget="${config.home.homeDirectory}/.commandcode/taste"
    run mkdir -p "${config.home.homeDirectory}/.commandcode"
    if [ -e "$tasteTarget" ] && [ ! -L "$tasteTarget" ]; then
      run rm -rf "$tasteTarget"
    fi
    run ln -sfn "$tasteRepo" "$tasteTarget"
  '';
}
