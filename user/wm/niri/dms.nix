{ dms, dms-plugin-diskusage, ... }:
{
  imports = [
    dms.homeModules.dank-material-shell
  ];

  programs.dank-material-shell = {
    enable = true;

    settings = {
      theme = "dark";
      dynamicTheming = true;
    };

    enableSystemMonitoring = false;
    enableVPN = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
    enableClipboardPaste = true;

    plugins.DankDiskUsage = {
      enable = true;
      src = dms-plugin-diskusage;
    };
  };
}
