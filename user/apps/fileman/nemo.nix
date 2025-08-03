{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nemo-with-extensions
    dbus
    samba
    gvfs
  ];
}

