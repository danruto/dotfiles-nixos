{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    cosmic-files
    # dbus
    # samba
    # gvfs
  ];
}
