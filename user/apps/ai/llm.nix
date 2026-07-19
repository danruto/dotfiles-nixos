{ pkgs, pkgs-unstable, pkgs-master, fff, crit, lib, config, platform, ... }:
let
  # Standalone home (e.g. orb-arch via `make hm/switch`) skips Pi: its install
  # activation shells out to a global npm install that fails on read-only/Nix
  # store setups, and Pi isn't wanted on that profile anyway.
  # piEnabled = platform != "standalone";
  piEnabled = true;

  fff-mcp = fff.packages.${pkgs.stdenv.hostPlatform.system}.default;
  crit-pkg = crit.packages.${pkgs.stdenv.hostPlatform.system}.default;
  lazypi = pkgs.callPackage ./lazypi.nix { };

  # nixpkgs is pinned to tokscale 4.0.4, whose checkPhase fails on a broken unit
  # test (usage_reset_button_renders_when_credit_available). Bump to the latest
  # upstream tag where the test passes. As with pi-coding-agent above, the src
  # override needs cargoHash recomputed since deps changed. Drop this once
  # nixpkgs advances past 4.0.4.
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

  # nixpkgs-master lags upstream Pi releases, but lazypi installs community
  # extensions rebuilt for the latest Pi, which can depend on newer exports of
  # `@earendil-works/pi-ai`. Pin to the latest upstream tag to match.
  # overrideAttrs alone updates the build src but leaves npmDeps pointing at
  # the old lockfile, so the offline cache must be rebuilt explicitly. Drop
  # this whole override once nixpkgs-master reaches >= 0.80.10.
  pi-src = pkgs-master.fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    tag = "v0.80.10";
    hash = "sha256-Vs/ndHYzFyfN4CjPV2zMYblLXe9IuM13UrPJI1VsZEQ=";
  };
  pi-coding-agent = pkgs-master.pi-coding-agent.overrideAttrs (o: {
    version = "0.80.10";
    src = pi-src;
    npmDeps = pkgs-master.fetchNpmDeps {
      src = pi-src;
      name = "pi-coding-agent-0.80.10-npm-deps";
      hash = "sha256-XGvDNH+eilsgc0Z7ITqbitB/9RVc+WuDfCcr1pibNqk=";
    };
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

  # Minimal Rust coding agent (https://github.com/gi-dellav/zerostack). Not in
  # nixpkgs; upstream's nix expr builds from source, so ship the release binary
  # instead. musl builds are fully static — no autoPatchelfHook needed.
  zerostack =
    let
      version = "1.6.2";
      sources = {
        "x86_64-linux" = { target = "x86_64-unknown-linux-musl"; hash = "sha256-uuRjPazVSvE8GlMW6yFkt2WdZZ5NjfkdLkSEF23yjOI="; };
        "aarch64-linux" = { target = "aarch64-unknown-linux-musl"; hash = "sha256-FMXmVQssmTtnXSkZtkP8pzGmQEs15IFUT2+2yNypFnM="; };
        "x86_64-darwin" = { target = "x86_64-apple-darwin"; hash = "sha256-ZcTYmqEb6nxIoNpAwjmCxCSEQo+vJdO2Q+XyVSr5U+U="; };
        "aarch64-darwin" = { target = "aarch64-apple-darwin"; hash = "sha256-3ln8Yq2POjWqCxngjoVndSoyLvoerD9OJxUft7Cr9ew="; };
      };
      target = sources.${pkgs.stdenv.hostPlatform.system};
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "zerostack";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://github.com/gi-dellav/zerostack/releases/download/v${version}/zerostack-${target.target}.tar.gz";
        inherit (target) hash;
      };
      sourceRoot = ".";
      installPhase = ''
        runHook preInstall
        install -Dm755 zerostack-${target.target} $out/bin/zerostack
        runHook postInstall
      '';
      meta = {
        description = "Minimal coding agent written in Rust, inspired by pi and opencode";
        homepage = "https://github.com/gi-dellav/zerostack";
        license = pkgs.lib.licenses.gpl3Only;
        mainProgram = "zerostack";
        platforms = builtins.attrNames sources;
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
    crit-pkg
    revdiff
    zerostack
    # amp-cli
    # gemini-cli
    # codex
    # nur.repos.charmbracelet.crush
  ]) ++ [
    tokscale
    pkgs-master.claude-code
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
