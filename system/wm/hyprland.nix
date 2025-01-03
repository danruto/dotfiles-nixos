{ pkgs, ... }:

{
  # Import wayland config
  imports = [
    # ./wayland.nix
  ];

  security.pam.services.login.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;

  programs = {
    hyprland = {
      enable = true;
      xwayland = {
        enable = true;
      };
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };
  };
}
