{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    opencode
    gemini-cli
  ];
}
