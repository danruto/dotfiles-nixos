{ pkgs, pkgs-unstable, fff, ... }:
let
  fff-mcp = fff.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = with pkgs-unstable; [
    opencode
    claude-code
    sox # voice for cc
    # amp-cli
    # gemini-cli
    # codex
    # nur.repos.charmbracelet.crush
  ];

  home.file.".claude/CLAUDE.md".source = ./configs/CLAUDE.md;
  home.file.".claude/commands/commit.md".source = ./configs/commands/commit.md;
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
