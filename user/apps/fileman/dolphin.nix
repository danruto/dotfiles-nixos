{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    dbus
    samba
    gvfs
  ];
}
