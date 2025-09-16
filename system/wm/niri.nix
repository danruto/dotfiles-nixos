{ pkgs, pkgs-unstable, niri, noctalia, quickshell, ... }:
{
  # Import wayland config
  imports = [
    # ./wayland.nix

    niri.nixosModules.niri
  ];

  nixpkgs.overlays = [ niri.overlays.niri ];

  environment.systemPackages = with pkgs-unstable; [
    xwayland-satellite
    noctalia.packages.${system}.default
    quickshell.packages.${system}.default
  ];

  # environment.variables.DISPLAY = ":0";
  environment.variables.NIX_OZONE_WL = "1";
  environment.variables.ELECTRON_OZONE_PLATFORM_HINT = "auto";

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };
}
