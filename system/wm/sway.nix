{ pkgs, ... }:

{
  # Import wayland config
  imports = [
    ./wayland.nix
    # ./pipewire.nix
  ];

  security.pam.services.swaylock = { };
  security.pam.services.login.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      wl-clipboard
      mako
      # alacritty
      foot
      dmenu
      grim
      slurp
      wf-recorder
    ];
  };

  # Enable xdg portal for screen sharing
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
