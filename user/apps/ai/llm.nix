{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    # opencode
    claude-code
    gemini-cli
    # codex
    # nur.repos.charmbracelet.crush
  ];
}
