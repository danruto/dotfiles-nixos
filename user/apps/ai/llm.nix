{ pkgs, pkgs-unstable, pkgs-master, fff, crit, ... }:
let
  fff-mcp = fff.packages.${pkgs.stdenv.hostPlatform.system}.default;
  crit-pkg = crit.packages.${pkgs.stdenv.hostPlatform.system}.default;

  revdiff =
    let
      version = "1.4.1";
      sources = {
        "x86_64-linux" = { suffix = "linux_amd64"; hash = "sha256-kfWxHJDENFX8dj4/F/Hbe7yJH2dK5PDbQBMl/dHyJ3k="; };
        "aarch64-linux" = { suffix = "linux_arm64"; hash = "sha256-X0tLH3W6nMYYgXvGjKvDO4aUpR6VuBshKAGSfHu/cX8="; };
        "x86_64-darwin" = { suffix = "darwin_amd64"; hash = "sha256-wpZDEdq1LcV7WTrC9lOJu3smlteDmCBxAcG67WejgG0="; };
        "aarch64-darwin" = { suffix = "darwin_arm64"; hash = "sha256-KmG4XGDZRQBJ9LgF81PQXLvCnM6zu6pf4MjmiDmq2H4="; };
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
  ]) ++ [
    pkgs-master.claude-code
    pkgs-master.opencode
  ];

  home.sessionVariables = {
    REVDIFF_POPUP_WIDTH = "90%";
    REVDIFF_POPUP_HEIGHT = "90%";
  };

  home.file.".claude/CLAUDE.md".source = ./configs/CLAUDE.md;
  home.file.".claude/settings.local.json".text =
    let
      base = builtins.fromJSON (builtins.readFile ./configs/settings.local.json);
      merged = base // {
        mcpServers = (base.mcpServers or { }) // {
          fff = {
            command = "${fff-mcp}/bin/fff-mcp";
            args = [ ];
          };
        };
      };
    in
    builtins.toJSON merged;
}
