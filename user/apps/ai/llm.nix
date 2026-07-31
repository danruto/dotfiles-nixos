{ pkgs, pkgs-unstable, pkgs-master, fff, lib, config, platform, ... }:
let
  # Standalone home (e.g. orb-arch via `make hm/switch`) skips Pi: its install
  # activation shells out to a global npm install that fails on read-only/Nix
  # store setups, and Pi isn't wanted on that profile anyway.
  # piEnabled = platform != "standalone";
  piEnabled = true;

  fff-mcp = fff.packages.${pkgs.stdenv.hostPlatform.system}.default;
  lazypi = pkgs.callPackage ./lazypi.nix { };

  # Keep tokscale pinned to 4.5.2: newer releases have repeatedly broken builds.
  # Do not bump it as part of general version updates; only change it when asked.
  tokscale = pkgs-unstable.tokscale.overrideAttrs (o: rec {
    version = "4.5.2";
    src = pkgs-unstable.fetchFromGitHub {
      owner = "junhoyeo";
      repo = "tokscale";
      tag = "v${version}";
      hash = "sha256-oscf5CGmvrps8XoO1OJ1Y+GmanIgpGNy0TR+vj5xoo4=";
    };
    cargoDeps = pkgs-unstable.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "tokscale-${version}-vendor";
      hash = "sha256-Wh2sYJitlDYJMiwze77988sydrYc8m3mNcwvpNvzMQc=";
    };
  });

  # nixpkgs-master now tracks upstream Pi closely enough that no version pin is
  # needed; if it falls behind again, re-add an overrideAttrs for version, src,
  # npmDeps and modelData (the latter two are hash-pinned separately and go
  # stale when only version + src are bumped).
  pi-coding-agent = pkgs-master.pi-coding-agent.overrideAttrs (o: {
    # pi spawns `npm install` at runtime for package extensions and compiles
    # native npm modules (e.g. node-pty) when installing/updating them;
    # node-gyp needs python on PATH. Scope these to pi's own wrapper instead
    # of the global profile (gcc/gnumake come from user/lang/cc). This
    # replaces the upstream wrapper, so re-add its ripgrep/fd.
    postFixup = ''
      wrapProgram $out/bin/pi \
        --prefix PATH : ${lib.makeBinPath (with pkgs-master; [ nodejs ripgrep fd python3 ])}
    '';
  });

  # nixpkgs-master lags the latest claude-code release and Opus 5 needs the
  # newest CLI. The derivation reads its version + per-platform sha256 from a
  # committed manifest.json, so override version + src to the latest release,
  # taking checksums from the upstream release manifest at
  # https://downloads.claude.ai/claude-code-releases/2.1.220/manifest.json.
  # Drop this override once nixpkgs-master reaches >= 2.1.220.
  claude-code =
    let
      version = "2.1.220";
      baseUrl = "https://downloads.claude.ai/claude-code-releases";
      platformKey = "${pkgs-master.stdenv.hostPlatform.node.platform}-${pkgs-master.stdenv.hostPlatform.node.arch}";
      # sha256 (hex) per platform, copied from the upstream manifest.json.
      checksums = {
        "darwin-arm64" = "8addc857f3fe64d5a0368af9ee50321b50afb4a6918ba3ef018ab84f5dbbe081";
        "darwin-x64" = "dca7be0aa7d3d924836d440e0c6d8e3d47ef3c8e61fa5809b54b9017170ce2f3";
        "linux-arm64" = "159e4a51d796f3bf14677577100f7efb845611b1ceaf0c30cbd8d4650d942185";
        "linux-x64" = "674f61f20ff306f3100cf9200e4c36c4b70278b5bef2884549819b942a89c863";
      };
    in
    pkgs-master.claude-code.overrideAttrs (o: {
      inherit version;
      src = pkgs-master.fetchurl {
        url = "${baseUrl}/${version}/${platformKey}/claude";
        sha256 = checksums.${platformKey};
      };
    });

  # opencode 1.18.3's build script runs a smoke test that executes the freshly
  # built binary. In the Nix sandbox (notably WSL) this binary segfaults
  # (exit code 139), failing the build even though the produced artifact is fine
  # for normal use. Skip the smoke test and the post-install shell completion
  # generation (which also invokes the binary) so the build can finish.
  opencode = pkgs-master.opencode.overrideAttrs (o: {
    postPatch = (o.postPatch or "") + ''
      substituteInPlace packages/opencode/script/build.ts \
        --replace-fail 'if (item.os === process.platform && item.arch === process.arch && !item.abi) {' \
                       'if (false) {'
    '';
    postInstall = "";
    doInstallCheck = false;
  });

  # Rust TUI coding agent (https://github.com/1jehuang/jcode). Not in nixpkgs
  # and upstream ships no nix expr, so build the `jcode` bin from the release
  # tag. The workspace also declares dev/bench bins, hence the explicit
  # --bin jcode.
  jcode =
    let
      version = "0.64.2";
      src = pkgs-unstable.fetchFromGitHub {
        owner = "1jehuang";
        repo = "jcode";
        tag = "v${version}";
        hash = "sha256-yT7TUztsE8oiVyKt6ZlPGpLZE0FTJ5UZVxLUTXBFRxg=";
      };
    in
    pkgs-unstable.rustPlatform.buildRustPackage {
      pname = "jcode";
      inherit version src;
      cargoHash = "sha256-wagEh+yIFi2uuAe/NXNIwoyK8qrzbTDbCmHyOpO+83k=";
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

  revdiff =
    let
      version = "1.11.1";
      sources = {
        "x86_64-linux" = { suffix = "linux_amd64"; hash = "sha256-eVimvvcjJn/tGLC+lkdrt2djav6WYzjtfjcMClBv1Uw="; };
        "aarch64-linux" = { suffix = "linux_arm64"; hash = "sha256-h8UiUW4tDvETt0/3KaHpByqtmVjxrraDa5DSuPouB2I="; };
        "x86_64-darwin" = { suffix = "darwin_amd64"; hash = "sha256-qOwp5pWNIIiVNt6WfQsSP0useXkVgVy9IP+6RNWEL4U="; };
        "aarch64-darwin" = { suffix = "darwin_arm64"; hash = "sha256-s+HYMqhS2LqKki0CPsKTQ7EdUgmtbNhNCeSnEP6NH74="; };
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
      nativeBuildInputs = pkgs.lib.optional pkgs.stdenv.isLinux pkgs.autoPatchelfHook;
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
    tokscale
    claude-code
    opencode
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
