{ pkgs, quickshell, dankMaterialShell, ... }:

{
  imports = [
    ./quickshell-module.nix
    dankMaterialShell.homeModules.dankMaterialShell.default
    dankMaterialShell.homeModules.dankMaterialShell.niri
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
    enableClipboard = false; # Clipboard history manager
    enableVPN = true; # VPN management widget
    enableBrightnessControl = true; # Backlight/brightness controls
    enableColorPicker = true; # Color picker tool
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)
    enableSystemSound = true; # System sound effects
  };
}
