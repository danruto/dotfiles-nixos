{ pkgs, niri, ... }:
{
  # Import wayland config
  imports = [
    # ./wayland.nix

    niri.nixosModules.niri
  ];

  nixpkgs.overlays = [ niri.overlays.niri ];

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
  environment.variables.NIXOS_OZONE_WL = "1";
  environment.variables.DISLPAY = ":0";

  programs.niri.enable = true;

}
