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

  # tokscale is pinned here because pkgs-unstable lags well behind (4.0.4) and
  # newer releases have repeatedly broken builds. Do not bump it as part of
  # general version updates; only change it when asked, and build it first.
  # doCheck = false: the inherited check phase compiles the full test suite on
  # top of an already-slow Rust build and upstream's cli_tests assume a non-UTC
  # local timezone, which never holds in the Nix sandbox (TZ=UTC). nixpkgs' CI
  # runs the tests; the base doInstallCheck still smoke-checks the binary.
  tokscale = pkgs-unstable.tokscale.overrideAttrs (o: rec {
    version = "4.13.0";
    src = pkgs-unstable.fetchFromGitHub {
      owner = "junhoyeo";
      repo = "tokscale";
      tag = "v${version}";
      hash = "sha256-0BQnoIDETgh6S806mHvxqDBpcJJQZbhl46yj6ctUTsk=";
    };
    cargoDeps = pkgs-unstable.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "tokscale-${version}-vendor";
      hash = "sha256-kuq1qT4OywO3miSoyMsTUo+o/3jcLjpzQ70lGHpvt+w=";
    };
    doCheck = false;
  });

  # Version + src come from nixpkgs-master; only the wrapper is overridden.
  pi-coding-agent = pkgs-master.pi-coding-agent.overrideAttrs (_: {
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
      version = "0.80.0";
      src = pkgs-unstable.fetchFromGitHub {
        owner = "1jehuang";
        repo = "jcode";
        tag = "v${version}";
        hash = "sha256-AVm2eZkVfQSuDCXDLcwyRzCLpi69/mHB9nW9WUnJMtA=";
      };
    in
    pkgs-unstable.rustPlatform.buildRustPackage {
      pname = "jcode";
      inherit version src;
      cargoHash = "sha256-XARbKIa6Hd7VXFxNXNS3AKMh7o6oCXLakLpjgG3euOE=";
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
      version = "0.0.0-dev-202608240735";
      hashes = {
        "x86_64-linux" = { plat = "linux-x64"; hash = "sha256-TYXVvRFOP72YqcBo6xln4fRcbB7MMjg5GIwg7ooubDY="; };
        "aarch64-linux" = { plat = "linux-arm64"; hash = "sha256-ifaK/IXSAzm2AW16ruMDZ9BMZgsO1gHybdyhM7Zkr4U="; };
        "x86_64-darwin" = { plat = "darwin-x64"; hash = "sha256-4dni4w4t+7RnrpGgEN7EIfoB4NYLQ0ApaQK3aNlExSA="; };
        "aarch64-darwin" = { plat = "darwin-arm64"; hash = "sha256-90AyqUdxB4kq1mSQpJ/NRaHecfRSnUHq0GfsJoEOuVg="; };
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
    pkgs-master.claude-code
    opencode-beta
    pkgs-master.codex
    fff-mcp # on PATH so Claude/Pi MCP configs can reference `fff-mcp` by name
  ] ++ lib.optionals piEnabled [
    pi-coding-agent
    lazypi
  ];

  # CLAUDE.md and Claude Code's settings.json are out-of-store symlinks to the
  # live working tree (like herdr's config.toml) so edits — including Claude
  # Code's own writes to settings.json — land directly in this repo without a
  # redeploy. Assumes the repo is checked out at ~/dotfiles-nixos. fff-mcp is on
  # PATH (see home.packages) so the static Claude/OMP MCP configs can reference
  # it by bare name instead of a store path.
  #
  # NOTE: Claude Code does NOT read `mcpServers` from settings.json — the key is
  # not in the settings schema and is silently ignored. MCP servers only load
  # from ~/.claude.json or a repo's .mcp.json. ~/.claude.json is mutable state
  # this flake does not manage, so on a fresh machine register fff manually:
  #     claude mcp add --scope user fff fff-mcp
  # Verify with `claude mcp list` (expect "fff: fff-mcp - ✔ Connected").
  # Pi's MCP config is unaffected and still reads its own settings file.
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/CLAUDE.md";

  home.file.".claude/statusline.sh".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/statusline.sh";

  home.file.".claude/subagent-statusline.sh".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/subagent-statusline.sh";

  # settings.json can't go through home.file/mkOutOfStoreSymlink: that routes the
  # link through the read-only home-manager-files store dir, and Claude Code
  # rewrites settings.json atomically (write a sibling .tmp, then rename). It
  # resolves only the first symlink hop, so the .tmp lands in /nix/store → EROFS
  # (breaks plugin installs, /config, etc.). Create a *direct* out-of-store
  # symlink to the live repo file instead, so the sibling .tmp lands in the
  # writable repo dir and Claude's own edits still sync straight back into git.
  home.activation.claudeSettingsLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.home.homeDirectory}/.claude"
    run ln -sf "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/settings.json" \
      "${config.home.homeDirectory}/.claude/settings.json"
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
    run ln -sf "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/pi-settings.json" \
      "${config.home.homeDirectory}/.pi/agent/settings.json"
    run ln -sf "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/pi-models.json" \
      "${config.home.homeDirectory}/.pi/agent/models.json"
    run ln -sf "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/pi-usage-status.ts" \
      "${config.home.homeDirectory}/.pi/agent/extensions/pi-usage-status.ts"
  '');
}
