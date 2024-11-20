{ niri, nixpkgs, pkgs, ... }:
let
  inherit (niri.lib.kdl) node plain leaf flag;
in
{
  # Import wayland config
  imports = [
    ./wayland.nix
    # ./pipewire.nix
    # ./dbus.nix

    niri.nixosModules.niri
  ];

  nixpkgs.overlays = [ niri.overlays.niri ];

  # Security
  security = {
    pam.services.swaylock = {
      text = ''
        auth include login
      '';
    };
    pam.services.login.enableGnomeKeyring = true;
  };

  programs.niri.enable = true;

}
