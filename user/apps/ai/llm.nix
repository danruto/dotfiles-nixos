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
        version = "2.1.261";
        platforms = {
          "darwin-arm64".checksum = "5efecaff231b798be3c66def9be54183623b328b80eaef17f93c43987024e82a";
          "darwin-x64".checksum = "2cbc002b32778bd70aa2e668ada920c54d9aacd91b71dbd5619c01ca148ae533";
          "linux-arm64".checksum = "7bbed5a9b0fc2e4ec67bad3490d06ca91b86d6b037d47520b7898951757d1b8a";
          "linux-x64".checksum = "4ae40dd1784e85753e742e09f267d29ecbb82890361ad3817d27560866d364a6";
      };
    };
  };

  # nixpkgs builds tokscale from Rust source, which takes far too long. Upstream
  # publishes the same release as prebuilt per-platform binaries on npm, so pull
  # those instead. Bumping means a new version + four integrity hashes from
  # `npm view @tokscale/cli-<plat> dist.integrity`.
  tokscale =
    let
      version = "4.15.1";
      sources = {
        "x86_64-linux" = { plat = "linux-x64-gnu"; hash = "sha512-bJLuRMnDWX4mXjgNma8DSJ6g/+xmSIt+eWrVOKgYcjQY4z2DJe6S0E9pH4trmUqmyTLk7KeynISOXEIBHz1jGw=="; };
        "aarch64-linux" = { plat = "linux-arm64-gnu"; hash = "sha512-W4YgugkNkh6TeApIbgjA+YYiogYl3NT0GPsTed/V8Qgh7b5Dv52Gp85ALgUvjUtKzPTC4g2wH0oE74w+9DZylg=="; };
        "x86_64-darwin" = { plat = "darwin-x64"; hash = "sha512-S6kdXgDmGSx2K7OjhdkywRa0eAzZMTzLpblMHGQSMTatW0BrE9DrVAY+dFRfySl9gCDAVVGSunwamQuw0DHU9w=="; };
        "aarch64-darwin" = { plat = "darwin-arm64"; hash = "sha512-mKyJH7pVRYMuITft3ffikSVakUeYO323d+pHht66CqhHSAsd7WX3e0YGkccq9LpQSDXiJeVknGM5iOY1D0WT7A=="; };
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
  pi-coding-agent = pkgs-master.pi-coding-agent.overrideAttrs (final: prev: {
    version = "0.85.0";
    src = pkgs-master.fetchFromGitHub {
      owner = "earendil-works";
      repo = "pi";
      tag = "v${final.version}";
      hash = "sha256-gznGlneVCx3htxRiJq0/futm4qLR9Bzfv3UwP3ES9v0=";
    };
    # npmDeps must be overridden directly, not via npmDepsHash: buildNpmPackage
    # bakes the resolved npmDeps into the derivation attrs, so on overrideAttrs
    # the hash argument is ignored and the old lockfile cache would be reused.
    npmDeps = pkgs-master.fetchNpmDeps {
      inherit (final) src;
      name = "pi-coding-agent-${final.version}-npm-deps";
      hash = "sha256-K/KiukwTHwu4HE8hUu7ur3bxggwfO0WL+QDI0FtxP3I=";
      fetcherVersion = 1;
    };
    # Hydrated model catalog; gitignored upstream, see nixpkgs' package.nix.
    modelData = pkgs-master.fetchurl {
      url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${final.version}.tgz";
      hash = "sha256-RhiL2stVWgdGagER85Y/IJMqFhmeTWz7jUSn/l/G40I=";
    };

    # 0.85.0 added the packages/chord workspace and coding-agent now imports
    # packages/server; nixpkgs 0.84.3 neither compiles nor copies either into
    # the output. Drop both with the pins above once nixpkgs-master catches up.
    buildPhase = builtins.replaceStrings
      [ "npx tsgo -p packages/tui/tsconfig.build.json" "npm run build --workspace=packages/coding-agent" ]
      [ "npx tsgo -p packages/chord/tsconfig.build.json\n    npx tsgo -p packages/tui/tsconfig.build.json"
        "npx tsgo -p packages/server/tsconfig.build.json\n    npm run build --workspace=packages/coding-agent" ]
      prev.buildPhase;
    postInstall = prev.postInstall + ''
      nm="$out/lib/node_modules/pi-monorepo/node_modules/@earendil-works"
      cp -r packages/chord "$nm/chord"
      cp -r packages/server "$nm/pi-server"
    '';

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
      version = "0.81.7";
      src = pkgs-unstable.fetchFromGitHub {
        owner = "1jehuang";
        repo = "jcode";
        tag = "v${version}";
        hash = "sha256-4aKuYFbGTdH0qi5uIgw/TOMxXcoHYUbLRzychST8BZU=";
      };
    in
    pkgs-unstable.rustPlatform.buildRustPackage {
      pname = "jcode";
      inherit version src;
      cargoHash = "sha256-mO5W3STCyqst0cTmH4RqBY2bAvWEV9Z/u9qHh4FO7pw=";
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
      version = "0.0.0-dev-202609041848";
      hashes = {
        "x86_64-linux" = { plat = "linux-x64"; hash = "sha512-oprn4npUMGpzRnyn3MGO6PLsaDi4Hcg8c7Uvge5Cb00WpRHwmQ6vIMHX8sAJn/0Gj0fnSw52D1+W6QiXl64G7g=="; };
        "aarch64-linux" = { plat = "linux-arm64"; hash = "sha512-CSUoBe3HFtd/0cPzUzBVtpoB6XBOINmjasK29P/3FPBCacrbBKQh63Ogbz4+QYOfWmuKQVJf44vSu8ZZZdubKg=="; };
        "x86_64-darwin" = { plat = "darwin-x64"; hash = "sha512-S6kdXgDmGSx2K7OjhdkywRa0eAzZMTzLpblMHGQSMTatW0BrE9DrVAY+dFRfySl9gCDAVVGSunwamQuw0DHU9w=="; };
        "aarch64-darwin" = { plat = "darwin-arm64"; hash = "sha512-mKyJH7pVRYMuITft3ffikSVakUeYO323d+pHht66CqhHSAsd7WX3e0YGkccq9LpQSDXiJeVknGM5iOY1D0WT7A=="; };
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
