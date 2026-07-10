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

  # nixpkgs-master lags upstream Pi releases, but lazypi installs community
  # extensions rebuilt for the latest Pi, which can depend on newer exports of
  # `@earendil-works/pi-ai`. Pin to the latest upstream tag to match.
  # overrideAttrs alone updates the build src but leaves npmDeps pointing at
  # the old lockfile, so the offline cache must be rebuilt explicitly. Drop
  # this whole override once nixpkgs-master reaches >= 0.80.6.
  pi-src = pkgs-master.fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    tag = "v0.80.6";
    hash = "sha256-e/wcHruEcBAHDF5tKvwew7LXjVp0eraHh2k+QaL2sCA=";
  };
  pi-coding-agent = pkgs-master.pi-coding-agent.overrideAttrs (o: {
    version = "0.80.6";
    src = pi-src;
    npmDeps = pkgs-master.fetchNpmDeps {
      src = pi-src;
      name = "pi-coding-agent-0.80.6-npm-deps";
      hash = "sha256-xXEOR0epZcfbXayYGyJdBiFVliamBexqA+1Sd7wlGhU=";
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
      version = "1.10.0";
      sources = {
        "x86_64-linux" = { suffix = "linux_amd64"; hash = "sha256-sh/aRX5toQJZQyiBQdgow2sL/Y33x+UX3uYd9qllKTM="; };
        "aarch64-linux" = { suffix = "linux_arm64"; hash = "sha256-fusqKrZkfZgEAL0kRDYadGI7ZTmwy1eswX3DdME4lFA="; };
        "x86_64-darwin" = { suffix = "darwin_amd64"; hash = "sha256-R+snH/SXgGC+sAtWZBVSOOs2l6ScMuErBnn9q6vC6y8="; };
        "aarch64-darwin" = { suffix = "darwin_arm64"; hash = "sha256-wxPrcrRG/WtuwtFRnnm+BOt+riAqSF7xg1xh2pQUkpI="; };
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
    tokscale
  ]) ++ [
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
