{ config, pkgs, ... }:
{
  home.packages = [ pkgs._1password-gui ];
}
