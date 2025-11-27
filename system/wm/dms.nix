{ pkgs, dankMaterialShell, quickshell, ... }:
{
  imports = [
    # ../../user/wm/niri/quickshell-module.nix
    dankMaterialShell.nixosModules.dankMaterialShell
  ];

  systemd.user.services.niri-flake-polkit.enable = false;

  programs.dankMaterialShell = {
    enable = true;
    quickshell.package = quickshell.packages.${pkgs.system}.default;
  };
}
