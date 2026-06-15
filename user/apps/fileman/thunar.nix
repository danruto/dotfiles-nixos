{ pkgs, ... }:
{
  services.gvfs.enable = true;

  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs; [
    thunar-archive-plugin
    thunar-volman
  ];

}
