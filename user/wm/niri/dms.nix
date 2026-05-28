{ dms, dms-plugin-diskusage, pkgs-unstable, ... }:
{
  imports = [
    dms.homeModules.dank-material-shell
  ];

  programs.dank-material-shell = {
    enable = true;

    dgop.package = pkgs-unstable.dgop;

    settings = {
      theme = "dark";
      dynamicTheming = true;
      use24HourClock = false;

      # settings.json is a read-only Nix store symlink, so the bar layout must be
      # declared here too — DMS can't persist GUI changes. barConfigs mirrors the
      # DMS default with the dankDiskUsage plugin widget added after memUsage.
      configVersion = 5;
      barConfigs = [
        {
          id = "default";
          name = "Main Bar";
          enabled = true;
          position = 0;
          screenPreferences = [ "all" ];
          showOnLastDisplay = true;
          leftWidgets = [ "launcherButton" "workspaceSwitcher" "focusedWindow" ];
          centerWidgets = [ "music" "clock" "weather" ];
          rightWidgets = [
            "systemTray"
            "clipboard"
            "cpuUsage"
            "cpuTemp"
            "memUsage"
            "dankDiskUsage"
            "network_speed_monitor"
            "vpn"
            "notificationButton"
            "battery"
            "controlCenterButton"
          ];
          spacing = 4;
          innerPadding = 4;
          bottomGap = 0;
          transparency = 1.0;
          widgetTransparency = 1.0;
          squareCorners = false;
          noBackground = false;
          maximizeWidgetIcons = false;
          maximizeWidgetText = false;
          removeWidgetPadding = false;
          widgetPadding = 8;
          gothCornersEnabled = false;
          gothCornerRadiusOverride = false;
          gothCornerRadiusValue = 12;
          borderEnabled = false;
          borderColor = "surfaceText";
          borderOpacity = 1.0;
          borderThickness = 1;
          widgetOutlineEnabled = false;
          widgetOutlineColor = "primary";
          widgetOutlineOpacity = 1.0;
          widgetOutlineThickness = 1;
          fontScale = 1.0;
          iconScale = 1.0;
          autoHide = false;
          autoHideDelay = 250;
          showOnWindowsOpen = false;
          openOnOverview = false;
          visible = true;
          popupGapsAuto = true;
          popupGapsManual = 4;
          maximizeDetection = true;
          scrollEnabled = true;
          scrollXBehavior = "column";
          scrollYBehavior = "workspace";
          shadowIntensity = 0;
          shadowOpacity = 60;
          shadowColorMode = "text";
          shadowCustomColor = "#000000";
          clickThrough = false;
        }
      ];
    };

    session = {
      weatherLocation = "Sydney, NSW";
      weatherCoordinates = "-33.8688,151.2093";
    };

    enableSystemMonitoring = true;
    enableVPN = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
    enableClipboardPaste = true;

    plugins.dankDiskUsage = {
      enable = true;
      src = dms-plugin-diskusage;
    };
  };
}
