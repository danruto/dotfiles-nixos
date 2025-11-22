{ pkgs, pkgs-unstable, niri, ... }:
{
  # Import wayland config
  imports = [
    # ./wayland.nix

    niri.nixosModules.niri
  ];

  nixpkgs.overlays = [ niri.overlays.niri ];

  environment.systemPackages = with pkgs-unstable; [
    xwayland-satellite
    quickshell
    noctalia-shell
  ];

  # environment.variables.DISPLAY = ":0";
  environment.variables.NIX_OZONE_WL = "1";
  environment.variables.ELECTRON_OZONE_PLATFORM_HINT = "auto";
  # HACK: tmp until author fixes bug
  environment.variables.USE_LAYER_SHELL = "0";

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  # services.noctalia.enable = true;
}
