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

  # nixpkgs-master lags upstream Pi (0.84.0 vs 0.84.1), so pin version + src
  # here. npmDeps and modelData are hash-pinned separately in the nixpkgs
  # derivation and go stale when only version + src are bumped, so both must be
  # rebuilt explicitly. Drop this whole pin once nixpkgs-master reaches >= 0.84.1.
  pi-src = pkgs-master.fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    tag = "v0.84.1";
    hash = "sha256-lg+I4S/aAjazjhGZU567ow+rksoNiqOqjHl//TjAMes=";
  };
  pi-coding-agent = pkgs-master.pi-coding-agent.overrideAttrs (_: {
    version = "0.84.1";
    src = pi-src;
    npmDeps = pkgs-master.fetchNpmDeps {
      src = pi-src;
      name = "pi-coding-agent-0.84.1-npm-deps";
      hash = "sha256-tufyZQRPAUeDtiq0UQodbKA/Y9xUAvNT8K+NWFjkeME=";
    };
    modelData = pkgs-master.fetchurl {
      url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.84.1.tgz";
      hash = "sha256-araJGJ58s95c2xJjEqPmDorDX+XuXxtj0A9xHIpDDHM=";
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

  # Prime Intellect's fork of pi (same monorepo layout, `.prime/agent` config
  # dir, `prime-agent` bin). Not in nixpkgs, so build it the same way nixpkgs
  # builds pi-coding-agent: tsgo the workspace deps in order, then the
  # coding-agent, then repair the workspace symlinks in the output. Unlike pi,
  # the model catalog (models.generated.ts) is committed upstream, so no
  # modelData fetch is needed — we only skip pi-ai's networked generate-models
  # script by calling tsgo directly.
  prime-agent =
    let
      version = "0.7.2";
      rawSrc = pkgs-master.fetchFromGitHub {
        owner = "PrimeIntellect-ai";
        repo = "prime-agent";
        tag = "v${version}";
        hash = "sha256-rOKFkKoV2Mfg2wHioZ+2Eo3Js6C4489hxTxVu38cgbA=";
      };

      # The committed package-lock.json is unusable offline: ~230 entries carry
      # no `resolved`/`integrity` (npm strips those under the repo's
      # `min-release-age` .npmrc cooldown), so the Nix npm fetcher can't
      # prefetch them. Regenerate the lock in a fixed-output derivation, which
      # is the only place network access is allowed. Version resolution stays
      # pinned by the hash below, so this is still reproducible. @opentelemetry
      # /api is an optional peer of @mistralai/mistralai that npm skips but
      # esbuild needs to bundle, so pull it in here; that changes package.json
      # too, hence both files are captured.
      lock = pkgs-master.runCommand "prime-agent-${version}-lock"
        {
          nativeBuildInputs = [ pkgs-master.nodejs pkgs-master.cacert ];
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          outputHash = "sha256-kGe70lFKNeEG5/AjdAWAZ4m7fO0Uq5kOkzaNYEwIrsA=";
        } ''
        cp -r ${rawSrc} src
        chmod -R u+w src
        cd src
        export HOME=$TMPDIR
        rm -f .npmrc package-lock.json
        npm install --package-lock-only --ignore-scripts --no-audit --no-fund @opentelemetry/api
        mkdir -p $out
        cp package.json package-lock.json $out/
      '';
    in
    pkgs-master.buildNpmPackage {
      pname = "prime-agent";
      inherit version;

      # .npmrc's `min-release-age=7` makes npm reject freshly published
      # versions even when the lock pins them, which fails the offline install.
      src = pkgs-master.runCommand "prime-agent-${version}-src" { } ''
        cp -r ${rawSrc} $out
        chmod -R u+w $out
        cp ${lock}/package.json ${lock}/package-lock.json $out/
        rm -f $out/.npmrc
      '';

      npmDepsHash = "sha256-i/8sMEoMwklI2nLpXBuY+yC9yafBtF+DCygeufM/6jg=";
      npmDepsFetcherVersion = 2;
      npmWorkspace = "packages/coding-agent";
      npmRebuildFlags = [ "--ignore-scripts" ];
      nativeBuildInputs = [ pkgs-master.makeBinaryWrapper ];

      buildPhase = ''
        runHook preBuild
        npx tsgo -p packages/tui/tsconfig.build.json
        npx tsgo -p packages/ai/tsconfig.build.json
        npx tsgo -p packages/agent/tsconfig.build.json
        npm run build --workspace=packages/coding-agent
        runHook postBuild
      '';

      # Workspace symlinks in the output point at packages/, which isn't there.
      # Replace the runtime ones with real copies and drop the rest. The source
      # bin is still named `pi` (the release tooling renames it at publish
      # time), so rename it here to avoid colliding with pi-coding-agent.
      postInstall = ''
        nm="$out/lib/node_modules/prime-agent/node_modules"
        for ws in @earendil-works/pi-ai:packages/ai \
                  @earendil-works/pi-agent-core:packages/agent \
                  @earendil-works/pi-tui:packages/tui; do
          IFS=: read -r pkg src <<< "$ws"
          rm "$nm/$pkg"
          cp -r "$src" "$nm/$pkg"
        done
        find "$nm" -type l -lname '*/packages/*' -delete
        find "$nm/.bin" -xtype l -delete
        mv "$out/bin/pi" "$out/bin/prime-agent"
      '';

      # Same runtime needs as pi: ripgrep/fd for search, node+python for the
      # IPython kernel and npm extension installs.
      postFixup = ''
        wrapProgram $out/bin/prime-agent \
          --prefix PATH : ${lib.makeBinPath (with pkgs-master; [ nodejs ripgrep fd python3 ])}
      '';

      meta = {
        description = "Self-improving RLM coding agent (Prime Intellect's pi fork)";
        homepage = "https://github.com/PrimeIntellect-ai/prime-agent";
        license = pkgs.lib.licenses.mit;
        mainProgram = "prime-agent";
      };
    };

  # Rust TUI coding agent (https://github.com/1jehuang/jcode). Not in nixpkgs
  # and upstream ships no nix expr, so build the `jcode` bin from the release
  # tag. The workspace also declares dev/bench bins, hence the explicit
  # --bin jcode.
  jcode =
    let
      version = "0.75.3";
      src = pkgs-unstable.fetchFromGitHub {
        owner = "1jehuang";
        repo = "jcode";
        tag = "v${version}";
        hash = "sha256-0dNE5PtYxozTLCxnntQMcr5xIQtZYtPCfuH1N4zR/ds=";
      };
    in
    pkgs-unstable.rustPlatform.buildRustPackage {
      pname = "jcode";
      inherit version src;
      cargoHash = "sha256-mFAQiaRkLOj96nTJjonWbrUDUt8a+2WnTinKc5BDERA=";
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
    prime-agent
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
