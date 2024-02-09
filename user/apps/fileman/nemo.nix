{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cinnamon.nemo-with-extensions
    dbus
    samba
    gvfs
  ];
}