{ pkgs, niri, ... }:
{
  # Import wayland config
  imports = [
    # ./wayland.nix

    niri.nixosModules.niri
  ];

  nixpkgs.overlays = [ niri.overlays.niri ];

  environment.systemPackages = with pkgs; [
    xwayland-satellite-unstable
  ];

  # environment.variables.DISPLAY = ":0";
  environment.variables.NIX_OZONE_WL = "1";
  environment.variables.ELECTRON_OZONE_PLATFORM_HINT = "auto";

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };
}
