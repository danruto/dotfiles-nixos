{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    opencode
    claude-code
    amp-cli
    # gemini-cli
    # codex
    # nur.repos.charmbracelet.crush
  ];

  home.file.".claude/CLAUDE.md".source = ./configs/CLAUDE.md;
  home.file.".claude/settings.json".source = ./configs/settings.json;
}
