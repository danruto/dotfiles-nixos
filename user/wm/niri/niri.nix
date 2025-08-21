{ niri, pkgs, lib, ... }:
let
  inherit (niri.lib.kdl) node plain leaf flag;
in
{
  imports = [
    ../waybar/waybar.nix
  ];

  home.packages = with pkgs; [
    wlr-randr
    # wlr-screencopy
    wl-clipboard
    xsel
    pamixer
    pavucontrol
    swayidle
    swaylock
    swaybg
    rofi-wayland
    xdg-desktop-portal-gnome
  ];


  systemd.user.services.swaybg = {
    Unit = {
      Description = "Wallpaper via swaybg";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -c '#000000'";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  programs.niri.settings = {
    input.touchpad = {
      tap = true;
      dwt = true;
      natural-scroll = true;
    };

    input.tablet.map-to-output = "eDP-1";
    input.touch.map-to-output = "eDP-1";

    # prefer-no-csd = true;

    outputs = {
      # Laptop
      "eDP-1" = {
        scale = 1.0;
        mode = {
          width = 2256;
          height = 1504;
          refresh = 59.999;
        };
        # position = { x = 1148; y = 1440; };
        position = { x = 1148; y = 2160; };
      };

      # USB-C DP Adapter (other monitor via hub)
      # "DP-1" = {
      #   scale = 1.0;
      #   mode = {
      #     width = 3440;
      #     height = 1440;
      #     refresh = 59.999;
      #   };
      #   position = { x = 0; y = 0; };
      # };

      # HDMI
      # "DP-4" = {
      #   scale = 1.0;
      #   mode = {
      #     width = 3440;
      #     height = 1440;
      #     refresh = 49.987;
      #   };
      #   position = { x = 0; y = 0; };
      # };

      "Dell Inc. Dell AW3418DW #ASM/RFCGshLd" = {
        scale = 1.0;
        mode = {
          width = 3440;
          height = 1440;
          refresh = 59.973;
        };
        position = { x = 0; y = 0; };
      };

      # Dell 4K Monitor (matches by name when connected directly)
      # "Dell Inc. DELL U3225QE 26VL734" = {
      "Dell Inc. Dell U3225QE 26VL734" = {
        scale = 1.0;
        mode = {
          width = 3840;
          height = 2160;
          refresh = 59.997;
        };
        position = { x = 0; y = 1440; };
      };

    };

    layout = {
      "focus-ring" = {
        width = 4;
        # active.color = "#7fc8ff";
        inactive.color = "#505050";
        # angle 45 => btmLeft to topRight
        active.gradient = { from = "#7fc8ff"; to = "#E6B673"; angle = 45; };
        # // active-gradient from="#80c8ff" to="#bbddff" angle=45
        # // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
        # // urgent-gradient from="#800" to="#a33" angle=45
      };

      border = {
        enable = false;
        width = 4;
        active.color = "#7fc8ff";
        inactive.color = "#505050";
      };

      # preset-column-widths = [
      #   { proportion = 1./3.; }
      #   { proportion = 1./2.; }
      #   { proportion = 2./3.; }
      # ];

      default-column-width = { proportion = 0.5; };

      gaps = 12;

      center-focused-column = "never";
    };

    screenshot-path = "~/screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    animations = {
      horizontal-view-movement = {
        kind = {
          spring = {
            damping-ratio = 1.0;
            stiffness = 800;
            epsilon = 0.0001;
          };
        };
      };

      window-open = {
        kind.spring = {
          damping-ratio = 0.8;
          stiffness = 1000;
          epsilon = 0.0001;
        };
      };
    };

    window-rules = [
      {
        matches = [{ app-id = "Slack"; }];
        block-out-from = "screencast";
      }
      {
        matches = [{ app-id = "Discord"; }];
        block-out-from = "screencast";
      }
      {
        matches = [{ app-id = "1Password"; }];
        block-out-from = "screencast";
      }
      {
        matches = [{ app-id = "dunst"; }];
        block-out-from = "screencast";
      }
      {
        matches = [{ app-id = "^org\.wezfurlong\.wezterm$"; }];
        default-column-width = { };
      }
    ];

    binds = {
      "Mod+Shift+Slash".action.show-hotkey-overlay = [ ];

      "Mod+T".action.spawn = "foot";
      "Mod+R".action.spawn = [ "bash" "-c" "rofi -show drun" ];
      "Super+Alt+L".action.spawn = "swaylock";

      "Mod+Shift+C".action.spawn = [ "sh" "-c" "env DISPLAY=:0" "xsel" "-ob" "|" "wl-copy" ];
      "Mod+Shift+V".action.spawn = [ "sh" "-c" "wlpaste -n" "|" "env DISPLAY=:0" "xsel" "-ib" ];

      "XF86AudioRaiseVolume".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+" ];
      "XF86AudioLowerVolume".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-" ];

      "Mod+Q".action.close-window = [ ];

      "Mod+Left".action.focus-column-left = [ ];
      "Mod+Down".action.focus-window-down = [ ];
      "Mod+Up".action.focus-window-up = [ ];
      "Mod+Right".action.focus-column-right = [ ];
      "Mod+H".action.focus-column-left = [ ];
      "Mod+J".action.focus-window-down = [ ];
      "Mod+K".action.focus-window-up = [ ];
      "Mod+L".action.focus-column-right = [ ];

      "Mod+Ctrl+Left".action.move-column-left = [ ];
      "Mod+Ctrl+Down".action.move-window-down = [ ];
      "Mod+Ctrl+Up".action.move-window-up = [ ];
      "Mod+Ctrl+Right".action.move-column-right = [ ];
      "Mod+Ctrl+H".action.move-column-left = [ ];
      "Mod+Ctrl+J".action.move-window-down = [ ];
      "Mod+Ctrl+K".action.move-window-up = [ ];
      "Mod+Ctrl+L".action.move-column-right = [ ];

      "Mod+Home".action.focus-column-first = [ ];
      "Mod+End".action.focus-column-last = [ ];
      "Mod+Ctrl+Home".action.move-column-to-first = [ ];
      "Mod+Ctrl+End".action.move-column-to-last = [ ];

      "Mod+Shift+Left".action.focus-monitor-left = [ ];
      "Mod+Shift+Down".action.focus-monitor-down = [ ];
      "Mod+Shift+Up".action.focus-monitor-up = [ ];
      "Mod+Shift+Right".action.focus-monitor-right = [ ];
      "Mod+Shift+H".action.focus-monitor-left = [ ];
      "Mod+Shift+J".action.focus-monitor-down = [ ];
      "Mod+Shift+K".action.focus-monitor-up = [ ];
      "Mod+Shift+L".action.focus-monitor-right = [ ];

      "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = [ ];
      "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = [ ];
      "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = [ ];
      "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = [ ];
      "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = [ ];
      "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = [ ];
      "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = [ ];
      "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = [ ];

      "Mod+Page_Down".action.focus-workspace-down = [ ];
      "Mod+Page_Up".action.focus-workspace-up = [ ];
      "Mod+U".action.focus-workspace-down = [ ];
      "Mod+I".action.focus-workspace-up = [ ];

      "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = [ ];
      "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = [ ];
      "Mod+Ctrl+U".action.move-column-to-workspace-down = [ ];
      "Mod+Ctrl+I".action.move-column-to-workspace-up = [ ];

      "Mod+Shift+Page_Down".action.move-workspace-down = [ ];
      "Mod+Shift+Page_Up".action.move-workspace-up = [ ];
      "Mod+Shift+U".action.move-workspace-down = [ ];
      "Mod+Shift+I".action.move-workspace-up = [ ];

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;

      "Mod+Ctrl+1".action.move-column-to-workspace = 1;
      "Mod+Ctrl+2".action.move-column-to-workspace = 2;
      "Mod+Ctrl+3".action.move-column-to-workspace = 3;
      "Mod+Ctrl+4".action.move-column-to-workspace = 4;
      "Mod+Ctrl+5".action.move-column-to-workspace = 5;
      "Mod+Ctrl+6".action.move-column-to-workspace = 6;
      "Mod+Ctrl+7".action.move-column-to-workspace = 7;
      "Mod+Ctrl+8".action.move-column-to-workspace = 8;
      "Mod+Ctrl+9".action.move-column-to-workspace = 9;

      "Mod+Comma".action.consume-window-into-column = [ ];
      "Mod+Period".action.expel-window-from-column = [ ];

      "Mod+D".action.switch-preset-column-width = [ ];
      "Mod+F".action.maximize-column = [ ];
      "Mod+Shift+F".action.fullscreen-window = [ ];
      "Mod+C".action.center-column = [ ];

      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";

      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";

      "Mod+Shift+S".action.screenshot = [ ];
      "Ctrl+Print".action.screenshot-screen = [ ];
      "Print".action.screenshot-window = [ ];

      "Mod+Shift+E".action.quit = [ ];
      "Mod+Shift+P".action.power-off-monitors = [ ];
    };

    xwayland-satellite = {
      enable = true;
      path = "${lib.getExe pkgs.xwayland-satellite-unstable}";
    };
  };

}


