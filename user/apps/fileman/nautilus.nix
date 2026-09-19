{ pkgs, ... }:
{
  # Nautilus (GNOME Files) is the default file manager. GVFS provides the
  # smb://, sftp:// and network:// backends in the sidebar.
  services.gvfs.enable = true;

  environment.systemPackages = [ pkgs.nautilus ];

  xdg.mime.defaultApplications = {
    "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
    "x-scheme-handler/smb" = [ "org.gnome.Nautilus.desktop" ];
    "x-scheme-handler/network" = [ "org.gnome.Nautilus.desktop" ];
  };
}
