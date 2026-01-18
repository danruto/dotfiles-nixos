{ pkgs, dankMaterialShell, quickshell, ... }:
{
  imports = [
    # ../../user/wm/niri/quickshell-module.nix
    dankMaterialShell.nixosModules.dank-material-shell
  ];

  systemd.user.services.niri-flake-polkit.enable = false;

  programs.dank-material-shell = {
    enable = true;
    quickshell.package = quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
    enableSystemMonitoring = false; # Disabled: dgop not available
  };
}
