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
}
