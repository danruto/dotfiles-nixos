{ niri, ... }:
{
  # Import wayland config
  imports = [
    # ./wayland.nix

    niri.nixosModules.niri
  ];

  nixpkgs.overlays = [ niri.overlays.niri ];

  programs.niri.enable = true;
}
