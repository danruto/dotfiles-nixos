{ pkgs, pkgs-unstable, pkgs-master, fff, crit, lib, config, platform, ... }:
let
  # Standalone home (e.g. orb-arch via `make hm/switch`) skips Pi: its install
  # activation shells out to a global npm install that fails on read-only/Nix
  # store setups, and Pi isn't wanted on that profile anyway.
  piEnabled = platform != "standalone";

  fff-mcp = fff.packages.${pkgs.stdenv.hostPlatform.system}.default;
  crit-pkg = crit.packages.${pkgs.stdenv.hostPlatform.system}.default;
  lazypi = pkgs.callPackage ./lazypi.nix { };

  # nixpkgs-master still ships pi-coding-agent 0.79.8, but lazypi installs
  # community extensions (e.g. pi-web-access@0.13.0) rebuilt for Pi 0.80.x,
  # which import `@earendil-works/pi-ai/compat` — a subpath export that only
  # exists from 0.80.0 on. Pin to 0.80.2 to match. overrideAttrs alone updates
  # the build src but leaves npmDeps pointing at the old 0.79.8 lockfile, so the
  # offline cache must be rebuilt explicitly. Drop this whole override once
  # nixpkgs-master reaches >= 0.80.2.
  pi-src = pkgs-master.fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    tag = "v0.80.2";
    hash = "sha256-aKtgPc3rwHEp856jP3N7nImph0CSG+gsWq9OVci3hmE=";
  };
  pi-coding-agent = pkgs-master.pi-coding-agent.overrideAttrs (o: {
    version = "0.80.2";
    src = pi-src;
    npmDeps = pkgs-master.fetchNpmDeps {
      src = pi-src;
      name = "pi-coding-agent-0.80.2-npm-deps";
      hash = "sha256-1EGs8lX8XoAnRtS+pw4lBRm24U/vtVB2loVRmZyd4Z8=";
    };
    # pi compiles native npm modules (e.g. node-pty) when installing/updating
    # extensions, and node-gyp needs python on PATH. Scope it to pi's own wrapper
    # instead of the global profile (gcc/gnumake come from user/lang/cc). This
    # replaces the upstream wrapper, so re-add its ripgrep/fd.
    postFixup = ''
      wrapProgram $out/bin/pi \
        --prefix PATH : ${lib.makeBinPath (with pkgs-master; [ ripgrep fd python3 ])}
    '';
  });

  revdiff =
    let
      version = "1.5.0";
      sources = {
        "x86_64-linux" = { suffix = "linux_amd64"; hash = "sha256-D+pgWTrubsZgEQx/dDs/7Jm2Ur8NW7Jm1cufivof1DU="; };
        "aarch64-linux" = { suffix = "linux_arm64"; hash = "sha256-EO+I3a926ZnP9mK4mCjJdaKQtrz4oG03/zKwwgHMb+E="; };
        "x86_64-darwin" = { suffix = "darwin_amd64"; hash = "sha256-Zu1/qUSh+kzSKBzMcmxvn+GQt8rYPqQvIaZW+Myildc="; };
        "aarch64-darwin" = { suffix = "darwin_arm64"; hash = "sha256-f9P2wWgs6WxiU6GafaIWU2fPCqEjznO+f9WHl5RIllk="; };
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
    # pkgs-master.opencode
    # opencode
    sox # voice for cc
    crit-pkg
    revdiff
    # amp-cli
    # gemini-cli
    # codex
    # nur.repos.charmbracelet.crush
    tokscale
  ]) ++ [
    pkgs-master.claude-code
    pkgs-master.opencode
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
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/settings.json";

  # LazyPi: one-shot installer for vanilla Pi + curated community packages.
  # Run once on first switch to seed ~/.pi/agent/settings.json; after that use
  # `lazypi update` / `lazypi remove` interactively. Compound Engineering is
  # excluded because it requires bunx and is the heaviest framework package.
  home.activation.lazyPiInstall = lib.mkIf piEnabled (lib.hm.dag.entryAfter [ "writeBoundary" ] (
    let
      settings = "${config.home.homeDirectory}/.pi/agent/settings.json";
    in
    ''
      if [ ! -f "${settings}" ]; then
        ${lazypi}/bin/lazypi install --yes --except compound
      fi
    ''
  ));

  # @ff-labs/pi-fff and pi-markdown-preview aren't in lazypi's catalog, so the
  # one-shot seed above drops them. Idempotently merge them into the package
  # list (preserving order, appending only what's missing) so they survive a
  # fresh ~/.pi reseed. Pi installs any newly-listed packages on next launch.
  home.activation.piExtraExtensions = lib.mkIf piEnabled (lib.hm.dag.entryAfter [ "lazyPiInstall" ] (
    let
      settings = "${config.home.homeDirectory}/.pi/agent/settings.json";
      extras = builtins.toJSON [ "npm:@ff-labs/pi-fff" "npm:pi-markdown-preview" ];
    in
    ''
      if [ -f "${settings}" ]; then
        tmp="$(mktemp)"
        ${pkgs.jq}/bin/jq --argjson e '${extras}' \
          '.packages = ((.packages // []) + ($e - (.packages // [])))' \
          "${settings}" > "$tmp" && mv "$tmp" "${settings}"
      fi
    ''
  ));
}
