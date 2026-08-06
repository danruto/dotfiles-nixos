{ pkgs, pkgs-unstable, pkgs-master, fff, lib, config, platform, ... }:
let
  # Standalone home (e.g. orb-arch via `make hm/switch`) skips Pi: its install
  # activation shells out to a global npm install that fails on read-only/Nix
  # store setups, and Pi isn't wanted on that profile anyway.
  # piEnabled = platform != "standalone";
  piEnabled = true;

  fff-mcp = fff.packages.${pkgs.stdenv.hostPlatform.system}.default;
  lazypi = pkgs.callPackage ./lazypi.nix { };

  # tokscale is pinned here because pkgs-unstable lags well behind (4.0.4) and
  # newer releases have repeatedly broken builds. Do not bump it as part of
  # general version updates; only change it when asked, and build it first.
  # 4.9.0's cli_tests assume a non-UTC local timezone, which never holds in the
  # Nix sandbox (TZ=UTC), so skip the offending test — nixpkgs already skips its
  # sibling test for the same reason.
  tokscale = pkgs-unstable.tokscale.overrideAttrs (o: rec {
    version = "4.9.0";
    src = pkgs-unstable.fetchFromGitHub {
      owner = "junhoyeo";
      repo = "tokscale";
      tag = "v${version}";
      hash = "sha256-LrzN+z4WqZoajDs3b1ihN9DPnAKIKPZZ+S666IZxs7o=";
    };
    cargoDeps = pkgs-unstable.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "tokscale-${version}-vendor";
      hash = "sha256-dogo+GXM8CwzyFJq6ryGaXAY1a4P3nR7LeYwPH2fGCI=";
    };
    checkFlags = (o.checkFlags or [ ]) ++ [
      "--skip=test_submit_dry_run_preserves_local_date_ahead_of_utc"
    ];
  });

  # nixpkgs-master lags upstream Pi (0.83.0 vs 0.84.0), so pin version + src
  # here. npmDeps and modelData are hash-pinned separately in the nixpkgs
  # derivation and go stale when only version + src are bumped, so both must be
  # rebuilt explicitly. Drop this whole pin once nixpkgs-master reaches >= 0.84.0.
  pi-src = pkgs-master.fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    tag = "v0.84.0";
    hash = "sha256-qySIyclHsWUo/Uap9rCl97amvKBbHfRXlOB16t8t3Ns=";
  };
  pi-coding-agent = pkgs-master.pi-coding-agent.overrideAttrs (o: {
    version = "0.84.0";
    src = pi-src;
    npmDeps = pkgs-master.fetchNpmDeps {
      src = pi-src;
      name = "pi-coding-agent-0.84.0-npm-deps";
      hash = "sha256-pIpwMAmSWjJKM5P+jltU/L/vS+d5JWNJYiIChfSZGOE=";
    };
    modelData = pkgs-master.fetchurl {
      url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.84.0.tgz";
      hash = "sha256-WWDOeXctyqZZmC8LENp3qeMvapehFSu7LMfsZh/LzOo=";
    };
    # 0.84.0 adds three workspace packages the upstream buildPhase doesn't know
    # about: pi-telemetry (used by ai + agent) and pi-protocol/pi-client (used by
    # coding-agent). Compile them in dependency order before their consumers.
    buildPhase = ''
      runHook preBuild

      npx tsgo -p packages/telemetry/tsconfig.build.json
      npx tsgo -p packages/protocol/tsconfig.build.json
      npx tsgo -p packages/ai/tsconfig.build.json
      npx tsgo -p packages/tui/tsconfig.build.json
      npx tsgo -p packages/agent/tsconfig.build.json
      npx tsgo -p packages/client/tsconfig.build.json
      npm run build --workspace=packages/coding-agent

      runHook postBuild
    '';
    # Those three are runtime deps too (pi-agent-core re-exports pi-telemetry),
    # but the upstream postInstall only materialises ai/agent/tui and then
    # deletes every remaining workspace symlink — materialise them first.
    postInstall = ''
      for extraWs in @earendil-works/pi-telemetry:packages/telemetry \
                     @earendil-works/pi-protocol:packages/protocol \
                     @earendil-works/pi-client:packages/client; do
        IFS=: read -r pkg src <<< "$extraWs"
        rm "$out/lib/node_modules/pi-monorepo/node_modules/$pkg"
        cp -r "$src" "$out/lib/node_modules/pi-monorepo/node_modules/$pkg"
      done
    '' + o.postInstall;
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

  # Rust TUI coding agent (https://github.com/1jehuang/jcode). Not in nixpkgs
  # and upstream ships no nix expr, so build the `jcode` bin from the release
  # tag. The workspace also declares dev/bench bins, hence the explicit
  # --bin jcode.
  jcode =
    let
      version = "0.67.0";
      src = pkgs-unstable.fetchFromGitHub {
        owner = "1jehuang";
        repo = "jcode";
        tag = "v${version}";
        hash = "sha256-E623Mf3DzSL5YhbqaL2onEVCsrEM8XQuhoi//JrdA7M=";
      };
    in
    pkgs-unstable.rustPlatform.buildRustPackage {
      pname = "jcode";
      inherit version src;
      cargoHash = "sha256-mDmwylu0GG5xguXsJefbQH1e+WjQ8rFHZcBNPtoy6k0=";
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
    pkgs-master.claude-code
    pkgs-master.opencode
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
