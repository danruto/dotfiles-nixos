{ pkgs, pkgs-unstable, pkgs-master, fff, crit, ... }:
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
  ]) ++ [
    pkgs-master.claude-code
    pkgs-master.opencode
  ];

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
