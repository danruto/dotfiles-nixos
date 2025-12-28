{ pkgs, quickshell, dankMaterialShell, ... }:

{
  imports = [
    ./quickshell-module.nix
    dankMaterialShell.homeModules.dank-material-shell
    dankMaterialShell.homeModules.niri
  ];

  programs.dankMaterialShell = {
    enable = true;
    niri = {
      enableSpawn = true;
    };
    quickshell.package = quickshell.packages.${pkgs.system}.default;
    default.settings = {
      theme = "dark";
      dynamicTheming = true;
      # Add any other settings here
    };

    default.session = {
      # Session state defaults
    };

    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)
  };
}
