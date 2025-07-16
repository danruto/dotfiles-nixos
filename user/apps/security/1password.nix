{ pkgs, ... }:
{
  home.packages = [ pkgs._1password-gui pkgs._1password-cli ];
}
