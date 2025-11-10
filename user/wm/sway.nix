{ config, lib, pkgs, ... }:

{

  # services.vicinae = {
  #   enable = true;
  #   autoStart = true;
  # };

  # Enable Sway window manager
  wayland.windowManager.sway = {
    enable = true;
    package = null;
    # checkConfig = false;

    config = rec {
      modifier = "Mod4"; # Use Super/Windows key
      terminal = "foot";
      menu = "vicinae toggle";

      # Startup applications
      startup = [
        { command = "waybar"; }
      ];

      # Key bindings
      keybindings = lib.mkOptionDefault {
        "${modifier}+Return" = "exec ${terminal}";
        "${modifier}+r" = "exec ${menu}";
        "${modifier}+Shift+q" = "kill";
        "${modifier}+Shift+c" = "reload";
        "${modifier}+Shift+e" = "exec swaynag -t warning -m 'Exit sway?' -b 'Yes' 'swaymsg exit'";

        # Focus
        "${modifier}+h" = "focus left";
        "${modifier}+j" = "focus down";
        "${modifier}+k" = "focus up";
        "${modifier}+l" = "focus right";

        # Move windows
        "${modifier}+Shift+h" = "move left";
        "${modifier}+Shift+j" = "move down";
        "${modifier}+Shift+k" = "move up";
        "${modifier}+Shift+l" = "move right";

        # Workspaces
        "${modifier}+1" = "workspace number 1";
        "${modifier}+2" = "workspace number 2";
        "${modifier}+3" = "workspace number 3";
        "${modifier}+4" = "workspace number 4";
        "${modifier}+5" = "workspace number 5";
        "${modifier}+6" = "workspace number 6";
        "${modifier}+7" = "workspace number 7";
        "${modifier}+8" = "workspace number 8";
        "${modifier}+9" = "workspace number 9";
        "${modifier}+0" = "workspace number 10";

        # Move to workspace
        "${modifier}+Shift+1" = "move container to workspace number 1";
        "${modifier}+Shift+2" = "move container to workspace number 2";
        "${modifier}+Shift+3" = "move container to workspace number 3";
        "${modifier}+Shift+4" = "move container to workspace number 4";
        "${modifier}+Shift+5" = "move container to workspace number 5";
        "${modifier}+Shift+6" = "move container to workspace number 6";
        "${modifier}+Shift+7" = "move container to workspace number 7";
        "${modifier}+Shift+8" = "move container to workspace number 8";
        "${modifier}+Shift+9" = "move container to workspace number 9";
        "${modifier}+Shift+0" = "move container to workspace number 10";

        # Layout
        "${modifier}+b" = "splith";
        "${modifier}+v" = "splitv";
        "${modifier}+f" = "fullscreen toggle";
        "${modifier}+s" = "layout stacking";
        "${modifier}+w" = "layout tabbed";
        "${modifier}+e" = "layout toggle split";

        # Floating
        "${modifier}+Shift+space" = "floating toggle";
        "${modifier}+space" = "focus mode_toggle";

        # Scratchpad
        "${modifier}+Shift+minus" = "move scratchpad";
        "${modifier}+minus" = "scratchpad show";
      };

      # Window and workspace settings
      gaps = {
        inner = 10;
        outer = 5;
      };

      # Bar configuration (we'll use waybar instead)
      bars = [ ];

      # Input configuration
      input = {
        "*" = {
          xkb_layout = "us";
          # Uncomment and adjust as needed:
          # xkb_variant = "";
          # xkb_options = "caps:escape";
        };
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
          dwt = "enabled";
        };
      };

      # Output configuration (monitors)
      output = {
        "*" = {
          # bg = "~/.config/wallpaper fill";
        };
      };

      # Colors (you can customize these)
      colors = {
        focused = {
          background = "#285577";
          border = "#4c7899";
          childBorder = "#285577";
          indicator = "#2e9ef4";
          text = "#ffffff";
        };
        focusedInactive = {
          background = "#5f676a";
          border = "#333333";
          childBorder = "#5f676a";
          indicator = "#484e50";
          text = "#ffffff";
        };
        unfocused = {
          background = "#222222";
          border = "#333333";
          childBorder = "#222222";
          indicator = "#292d2e";
          text = "#888888";
        };
        urgent = {
          background = "#900000";
          border = "#2f343a";
          childBorder = "#900000";
          indicator = "#900000";
          text = "#ffffff";
        };
      };
    };

    # Extra Sway configuration
    extraConfig = ''
      # Additional custom configuration can go here
      hide_edge_borders --i3 smart
    '';
  };

  # Waybar status bar
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;

        modules-left = [ "sway/workspaces" "sway/mode" ];
        modules-center = [ "sway/window" ];
        modules-right = [ "cpu" "memory" "clock" ];

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
        };

        "sway/mode" = {
          format = "<span style=\"italic\">{}</span>";
        };

        clock = {
          format = "{:%Y-%m-%d %h:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        cpu = {
          format = "CPU: {usage}%";
          tooltip = false;
        };

        memory = {
          format = "MEM: {}%";
        };

        network = {
          format-wifi = "WIFI: {essid} ({signalStrength}%)";
          format-ethernet = "ETH: {ifname}";
          format-disconnected = "Disconnected";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
        };

        pulseaudio = {
          format = "VOL: {volume}%";
          format-muted = "MUTE";
          on-click = "pavucontrol";
        };
      };
    };

    style = ''
      * {
        font-family: "JetBrains Mono", monospace;
        font-size: 13px;
      }

      window#waybar {
        background-color: rgba(43, 48, 59, 0.9);
        border-bottom: 3px solid rgba(100, 114, 125, 0.5);
        color: #ffffff;
      }

      #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #ffffff;
        border-bottom: 3px solid transparent;
      }

      #workspaces button.focused {
        background-color: #64727d;
        border-bottom: 3px solid #ffffff;
      }

      #mode {
        background-color: #64727d;
        border-bottom: 3px solid #ffffff;
      }

      #clock, #cpu, #memory, #network, #pulseaudio {
        padding: 0 10px;
        margin: 0 5px;
      }
    '';
  };

  # Application launcher
  programs.wofi = {
    enable = true;
    settings = {
      width = 600;
      height = 400;
      show = "drun";
      prompt = "Search...";
      allow_images = true;
      insensitive = true;
    };
  };

  # Notification daemon
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      border-radius = 5;
      border-color = "#4c7899";
      border-size = 2;
      background-color = "#285577";
      text-color = "#ffffff";
    };
  };

  # Additional Wayland utilities
  home.packages = with pkgs; [
    # Wayland tools
    wl-clipboard # Clipboard utilities
    grim # Screenshot tool
    slurp # Screen area selection
    swaylock # Screen locker
    swayidle # Idle management
    wlsunset # Color temperature adjustment
    wdisplays # Display configuration GUI
    pavucontrol # Audio control
    brightnessctl # Brightness control (if on laptop)

    # Additional utilities
    kanshi # Dynamic display configuration
  ];

  # Session variables for Wayland
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
