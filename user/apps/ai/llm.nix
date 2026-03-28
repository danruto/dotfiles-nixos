{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    opencode
    claude-code
    amp-cli
    # gemini-cli
    # codex
    # nur.repos.charmbracelet.crush
    sox
  ];

  home.file.".claude/CLAUDE.md".source = ./configs/CLAUDE.md;
  home.file.".claude/settings.local.json".source = ./configs/settings.local.json;
}
