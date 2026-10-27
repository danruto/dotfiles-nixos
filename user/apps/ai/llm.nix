{ pkgs, pkgs-unstable, pkgs-master, fff, lib, config, ... }:
let
  # Standalone home (e.g. orb-arch via `make hm/switch`) skips Pi: its install
  # activation shells out to a global npm install that fails on read-only/Nix
  # store setups, and Pi isn't wanted on that profile anyway.
  # piEnabled = platform != "standalone";
  piEnabled = true;

  fff-mcp = fff.packages.${pkgs.stdenv.hostPlatform.system}.default;
  lazypi = pkgs.callPackage ./lazypi.nix { };
  pi-pig = pkgs.callPackage ./pi-pig.nix {
    agentDir = "${config.home.homeDirectory}/.pig/agent";
  };
  piAgentDirs = [ ".pi/agent" ".pig/agent" ];
  dsh = pkgs-unstable.callPackage ./dsh.nix { };
  command-code = pkgs-unstable.callPackage ./command-code.nix { };

  # nixpkgs-master fetches zstd-compressed binaries; take checksums from
  # https://downloads.claude.ai/claude-code-releases/<version>/manifest.zst.json
  claude-code-unwrapped = pkgs-master.claude-code.override {
    manifest = {
      version = "2.1.310";
      platforms = {
        "darwin-arm64" = { binary = "claude.zst"; checksum = "0252ecc7c918fccc5a68d6f25a80c4579c4cf99fad8b315228236c2ee9c3f4af"; };
        "darwin-x64" = { binary = "claude.zst"; checksum = "7c82300870d0b0eb565922f6e12bf7ebc0a1e3a35ebb61af55aab883af62d680"; };
        "linux-arm64" = { binary = "claude.zst"; checksum = "ad34932dfad2bd67c328b9358acaac7c998e8113dc065dd328958b984a73fe27"; };
        "linux-x64" = { binary = "claude.zst"; checksum = "9314f28f679546a97813f2914c4fb60a190801ef782805f47bf197317cc4ffd2"; };
      };
    };
  };

  # Load pb straight from the live checkout instead of the pb-skills marketplace,
  # whose installed copy is a stale snapshot under <config dir>/plugins/cache.
  # Wrapping the binary (not a fish function) covers every launcher: claude,
  # claude-healix, claude-nm and herdr. The flag is accepted before subcommands,
  # and a missing dir on hosts without the checkout is ignored.
  claude-code = pkgs.symlinkJoin {
    name = "claude-code-${claude-code-unwrapped.version}";
    paths = [ claude-code-unwrapped ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --add-flags "--plugin-dir ${config.home.homeDirectory}/dev/pixelbrush/pb-skills/plugins/pb"
    '';
    inherit (claude-code-unwrapped) meta;
  };

  # nixpkgs builds tokscale from Rust source, which takes far too long. Upstream
  # publishes the same release as prebuilt per-platform binaries on npm, so pull
  # those instead. Bumping means a new version + four integrity hashes from
  # `npm view @tokscale/cli-<plat> dist.integrity`.
  tokscale =
    let
      version = "4.20.1";
      sources = {
        "x86_64-linux" = { plat = "linux-x64-gnu"; hash = "sha512-ekkNcNnXzDS6UdL5qlb3gRzWmE3NiwHXYqvwJU+EiI+3Gi4DKMyTm406gYwv+B6dhRfYA5YLyMeHsNUoiDDRNw=="; };
        "aarch64-linux" = { plat = "linux-arm64-gnu"; hash = "sha512-pxv1BSVMIPbGj1ne/o/PqDdRMBfBfLLEAEWKsxjsGDs22p7boaXEM2cLXR4G70eprUv8KH0NPllmFwqb5jHnwQ=="; };
        "x86_64-darwin" = { plat = "darwin-x64"; hash = "sha512-YRhKmVczmh1Ca+Pv4LqeoypT2mgD7mE1MLaaqUSzOH4y/XM04GV9//Zjjpx48HEiHRgH7p+H2IU/xE4EbzyzLw=="; };
        "aarch64-darwin" = { plat = "darwin-arm64"; hash = "sha512-aHI7EKMQNfe80A1FGPX9HbyPZ4XF3pjm13rZCssdWIvx5AZBWtFua54she9AwcgagxIxuk754NywuWHPz30jrA=="; };
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

  pi-coding-agent = pkgs-master.callPackage ./pi.nix { };

  # opencode v2 ships as prebuilt bun binaries under the @opencode/cli npm
  # scope; nixpkgs' `opencode` is still the v1 source build. Bumping means a
  # new version + four hashes from
  # `npm view @opencode/cli-<plat>@<version> dist.integrity`.
  opencode =
    let
      version = "2.1.4";
      hashes = {
        "x86_64-linux" = { plat = "linux-x64"; hash = "sha512-o8EJ0ZsT4dzDKN+0mpG2EKbNGzJyp+F1++Av28UReRVfiEv+N34eZEnN/unkiMoerKHad6W6Ii7k4ukTnPNmNQ=="; };
        "aarch64-linux" = { plat = "linux-arm64"; hash = "sha512-drw0LWMG0niaE94ePXm1h7qjFBZZRcSZD3gact3hx3OYPXesp7xrOt0bn3sicYNUN6fojERrDKR6jYrXmZX+rA=="; };
        "x86_64-darwin" = { plat = "darwin-x64"; hash = "sha512-pdx0Iyl+IK1SdSQOhvz8JE4Rk0PGyacZ55FaxmyowYe9h0aFZNs3UAj7wNYod6Hsu4qsAeSVkdfQLr4SI8G1oA=="; };
        "aarch64-darwin" = { plat = "darwin-arm64"; hash = "sha512-QwjyvovTdT0gFi5rxUyPVlYePIe3ELduR9olu+KJWe089XVIDOTMhxylBe/ZGIpvoXHYo6bp2NskIiqCFAEXsw=="; };
      };
      target = hashes.${pkgs.stdenv.hostPlatform.system};
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "opencode";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@opencode/cli-${target.plat}/-/cli-${target.plat}-${version}.tgz";
        inherit (target) hash;
      };
      nativeBuildInputs = [ pkgs.makeBinaryWrapper ]
        ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.autoPatchelfHook;
      installPhase = ''
        runHook preInstall
        install -Dm755 bin/opencode $out/bin/opencode
        wrapProgram $out/bin/opencode \
          --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep pkgs.sqlite ]} \
          --set OPENCODE_DISABLE_AUTOUPDATE true
        runHook postInstall
      '';
      # bun --compile binary: the JS payload is appended to the ELF, stripping
      # it corrupts the executable (nixpkgs' own opencode does the same).
      dontStrip = true;
      meta = {
        description = "AI coding agent built for the terminal";
        homepage = "https://github.com/anomalyco/opencode";
        platforms = builtins.attrNames hashes;
        mainProgram = "opencode";
      };
    };

  revdiff =
    let
      version = "1.13.0";
      sources = {
        "x86_64-linux" = { suffix = "linux_amd64"; hash = "sha256-bML8vcsuhlpwY5RfBzX2mRb2jMIaiGhUIXIzx5PttMc="; };
        "aarch64-linux" = { suffix = "linux_arm64"; hash = "sha256-QEkq6zalfxDCvKGlzJX66GnXI2v7BO+32dHD2ChRr/U="; };
        "x86_64-darwin" = { suffix = "darwin_amd64"; hash = "sha256-6TPjW/kbKuIKXIP3+d+KsNBpfx49b9l1qAnLOQnejPY="; };
        "aarch64-darwin" = { suffix = "darwin_arm64"; hash = "sha256-mXzMnxZP4HIOY0m9k8c+eennDdAFjufMeoysTBYx6aQ="; };
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
  claudeDirs = [ ".claude" ".claude-healix" ".claude-nm" ];
in
{
  home.packages = (with pkgs-unstable; [
    # opencode
    sox # voice for cc
    revdiff
    # amp-cli
    # gemini-cli
    # codex
    # nur.repos.charmbracelet.crush
  ]) ++ [
    dsh
    tokscale
    command-code
    claude-code
    opencode
    pkgs-unstable.codex
    fff-mcp # on PATH so Claude/Pi MCP configs can reference `fff-mcp` by name
  ] ++ lib.optionals piEnabled [
    pi-coding-agent
    lazypi
  ] ++ lib.optionals (piEnabled && lib.meta.availableOn pkgs.stdenv.hostPlatform pi-pig) [
    pi-pig
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
  # Pi/PiG share settings below; native MCP server definitions live in mcp.json.
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
  } // lib.optionalAttrs piEnabled (lib.foldl' lib.mergeAttrs { } (map
    (dir: {
      "${dir}/AGENTS.md".source =
        config.lib.file.mkOutOfStoreSymlink "${aiConfigs}/CLAUDE.md";
    })
    piAgentDirs)) // lib.optionalAttrs (piEnabled && lib.meta.availableOn pkgs.stdenv.hostPlatform pi-pig) {
    ".pig/agent/extensions/herdr-pig-agent-state.ts".source = pi-pig.herdrExtension;
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
  #
  # The theme at "<config dir>/themes/base16.json" is deliberately not linked
  # here: scripts/theme-render writes it in place, and Claude Code only
  # hot-reloads the active theme by watching that directory for events on the
  # file itself.
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

  # Pi and PiG share direct out-of-store config links: settings writes land in
  # the live repo, not a read-only home-manager store path. Their auth, sessions
  # and package installations remain separate. These links intentionally use
  # the repo as authoritative; detached local copies are replaced on activation.
  # scripts/theme-render owns Pi's theme file; PiG reuses its theme directory.
  home.activation.piConfigLinks = lib.mkIf piEnabled (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for dir in ${lib.concatMapStringsSep " " (d: ''"${config.home.homeDirectory}/${d}"'') piAgentDirs}; do
      run mkdir -p "$dir/extensions"
      run ln -sfn "${aiConfigs}/pi-settings.json" "$dir/settings.json"
      run ln -sfn "${aiConfigs}/pi-models.json" "$dir/models.json"
      run ln -sfn "${aiConfigs}/pi-claude-bridge.json" "$dir/claude-bridge.json"
      run ln -sfn "${aiConfigs}/pi-usage-status.ts" "$dir/extensions/pi-usage-status.ts"
    done
    run mkdir -p "${config.home.homeDirectory}/.pi/agent/themes"
    run ln -sfn "${config.home.homeDirectory}/.pi/agent/themes" \
      "${config.home.homeDirectory}/.pig/agent/themes"
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
