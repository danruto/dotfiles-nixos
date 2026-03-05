{ config, pkgs, ... }:

{
  services.dbus = {
    enable = true;
    packages = [ pkgs.dconf ];
  };

  programs.dconf = {
    enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common = {
      default = [ "gtk" ];
    };
  };
}
