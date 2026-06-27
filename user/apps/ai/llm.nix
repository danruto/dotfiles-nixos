{ pkgs, pkgs-unstable, pkgs-master, fff, crit, lib, config, ... }:
let
  fff-mcp = fff.packages.${pkgs.stdenv.hostPlatform.system}.default;
  crit-pkg = crit.packages.${pkgs.stdenv.hostPlatform.system}.default;

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
    pkgs-master.pi-coding-agent
    fff-mcp # on PATH so the static settings.json can reference `fff-mcp` by name
  ];

  # CLAUDE.md and settings.json are out-of-store symlinks to the live working
  # tree (like herdr's config.toml) so edits — including Claude Code's own writes
  # to settings.json — land directly in this repo without a redeploy. Assumes the
  # repo is checked out at ~/dotfiles-nixos. fff-mcp is on PATH (see home.packages)
  # so the static config can reference it by bare name instead of a store path.
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/CLAUDE.md";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/settings.json";

  # Pi agent config. Set OPENCODE_API_KEY in your environment (e.g. via a
  # secrets manager or direnv) so pi can authenticate against the OpenCode Go
  # provider. The activation script writes auth.json from that env var so you
  # don't have to /login manually.
  home.file.".pi/agent/settings.json".text = builtins.toJSON {
    defaultProvider = "opencode-go";
    theme = "dark";
    quietStartup = false;
    compaction = {
      enabled = true;
      reserveTokens = 16384;
      keepRecentTokens = 20000;
    };
    retry = {
      enabled = true;
      maxRetries = 3;
    };
    packages = [
      "pi-mcp-adapter"
      "pi-web-access"
      "pi-hermes-memory"
      "npm:@ff-labs/pi-fff"
      # "npm:pi-revdiff-plan"
      "npm:@plannotator/pi-extension"
      "npm:pi-ask-user"
      "npm:pi-markdown-preview"
    ];
  };

  # Custom model definitions for pi (built-in model lists are outdated in nixpkgs)
  home.file.".pi/agent/models.json".text = builtins.toJSON {
    providers = {
      opencode-go = {
        models = [
          {
            id = "kimi-k2.7-code";
            name = "Kimi K2.7 Code";
            reasoning = true;
            input = [ "text" "image" ];
            contextWindow = 262144;
            maxTokens = 262144;
          }
        ];
      };
    };
  };

  home.activation.piAuth = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    let authFile = "${config.home.homeDirectory}/.pi/agent/auth.json";
    in ''
      if [ -n "''${OPENCODE_API_KEY:-}" ]; then
        mkdir -p "${config.home.homeDirectory}/.pi/agent"
        ${pkgs.jq}/bin/jq -n \
          --arg key "$OPENCODE_API_KEY" \
          '{ "opencode-go": { "type": "api_key", "key": $key } }' \
          > "${authFile}"
      fi
    ''
  );
}
