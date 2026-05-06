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
