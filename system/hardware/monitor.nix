{ config, pkgs, ... }:
{
  # services.autorandr.enable = true;
  home.packages = with pkgs; [
    nwg-displays
  ];

  services.kanshi = {
    enable = true;
    systemdTarget = "hyprland-session.target";

    profiles = {
      undocked = {
        outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
          }
        ];
      };

      docked = {
        outputs = [
          {
            criteria = "DP-3";
            status = "enable";
          }
          {
            criteria = "eDP-1";
            status = "disable";
          }
        ];
      };
    };
  };
}
