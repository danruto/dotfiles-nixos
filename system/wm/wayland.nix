{ config, lib, pkgs, ... }:

{
  imports = [ ./pipewire.nix
              ./dbus.nix
              ./gnome-keyring.nix
              ./fonts.nix
            ];

  environment.systemPackages = with pkgs; [ 
    wayland 
    xwayland
    meson
    wayland-protocols
    wayland-utils
    wl-clipboard
    wlroots
  ];

  # Configure xwayland
  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "";
    xkbOptions = "caps:escape";
    displayManager.gdm = {
      enable = true;
      wayland = true;
      # defaultSession = "Hyprland";
    };
  };
}
