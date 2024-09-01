{ config, lib, pkgs, stdenv, toString, browser, term, font, hyprland-plugins, ... }:
let
  statusbar = pkgs.writeShellScriptBin "statusbar" (builtins.readFile ./statusbar.sh);
  switch = pkgs.writeShellScriptBin "switch" (builtins.readFile ./switch.sh);
  xdg = pkgs.writeShellScriptBin "xdg" (builtins.readFile ./xdg.sh);
in
{
  # home.file.".config/hypr/statusbar.sh".source = ./statusbar.sh;
  # home.file.".config/hypr/switch.sh".source = ./switch.sh;
  # home.file.".config/hypr/xdg.sh".source = ./xdg.sh;
  home.file.".config/waybar/scripts" = {
    source = ../../config/waybar/scripts;
    recursive = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    plugins = [
      #  (pkgs.callPackage ./hyprbars.nix { inherit hyprland-plugins; } )
    ];
    settings = {
      "$mainMod" = "SUPER";
      monitor = ",preferred,auto,1";
      bindl = [
        ",switch:Lid Switch, exec, ${lib.getExe switch}"
      ];

      exec-once = [
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "${lib.getExe xdg}"
        "${lib.getExe pkgs.dunst}"
        "${lib.getExe statusbar}"
        # "${lib.getExe pkgs.waybar}"
      ];

      env = "XCURSOR_SIZE,24";

      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = false;
          disable_while_typing = true;
        };
        sensitivity = 0;
      };

      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";

        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        blur = {
          size = 3;
        };
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = {
        new_status = "master";
      };

      gestures = {
        workspace_swipe = false;
      };


      bindm = [
        # Move/resize windows with mainMod + LMB/RMB and dragging
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      bind = [
        "$mainMod, M, exec, kitty"
        "$mainMod, Return, exec, alacritty"
        "$mainMod, Q, killactive,"
        "$mainMod, E, exec, nemo"
        "$mainMod, V, togglefloating,"
        "$mainMod, R, exec, rofi -show run"
        "$mainMod, P, pseudo, # dwindle"
        "$mainMod, N, togglesplit, # dwindle"

        # Move focus with mainMod + arrow keys
        "$mainMod, H, movefocus, l"
        "$mainMod, L, movefocus, r"
        "$mainMod, K, movefocus, u"
        "$mainMod, J, movefocus, d"

        # Scroll through existing workspaces with mainMod + scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"


        # Screenshotting
        # "$mainMod SHIFT, S, exec, hyprshot -m region"
        "$mainMod SHIFT, S, exec, grimblast copy area"
      ] ++ (
        builtins.concatLists (builtins.genList
          (
            x:
            let
              ws =
                let
                  c = (x + 1) / 10;
                in
                builtins.toString (x + 1 - (c * 10));
            in
            [
              "$mainMod, ${ws}, workspace, ${builtins.toString (x + 1)}"
              "$mainMod SHIFT, ${ws}, movetoworkspace, ${builtins.toString (x + 1)}"
            ]
          )
          10)

      );
    };

    # extraConfig = '';
    xwayland = { enable = true; };
    systemd.enable = true;
  };

  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      postPatch = ''
        # use hyprctl to switch workspaces
        # sed -i 's/zext_workspace_handle_v1_activate(workspace_handle_);/const std::string command = "hyprworkspace " + name_;\n\tsystem(command.c_str());/g' src/modules/wlr/workspace_manager.cpp
        # sed -i 's/gIPC->getSocket1Reply("dispatch workspace " + std::to_string(id()));/const std::string command = "hyprworkspace " + std::to_string(id());\n\tsystem(command.c_str());/g' src/modules/hyprland/workspaces.cpp
      '';
    });
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 35;
        margin = "0 0 0 0";
        spacing = 5;

        modules-left = [ "custom/launcher" "hyprland/workspaces" ];
        modules-center = [ "hyprland/window" ];
        modules-right = [ "tray" "disk" "cpu" "memory" "backlight" "pulseaudio" "network" "battery" "clock" "custom/power-menu" ];

        "hyprland/workspaces" = {
          "on-click" = "activate";
          "format-icons" = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
            "urgent" = "";
            "active" = "";
            "default" = "";
          };
        };

        "hyprland/window" = {
          "format" = "{}";
        };

        "tray" = {
          "spacing" = 10;
        };

        "clock" = {
          "format" = "<span color='#bf616a'> </span>{:%I:%M %p %d/%m}";
          "format-alt" = "<span color='#bf616a'> </span>{:%a %b %d}";
          "tooltip-format" = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "cpu" = {
          "interval" = 10;
          "format" = "󰻠 {}%";
          "max-length" = 10;
          "on-click" = "";
        };

        "memory" = {
          "interval" = 30;
          "format" = " {}%";
          "format-alt" = " {used:0.1f}G";
          "max-length" = 10;
        };

        "backlight" = {
          "device" = "intel_backlight";
          "format" = "{icon} {percent}%";
          "format-icons" = [
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
          ];
          "on-click" = "";
        };

        "network" = {
          "format-wifi" = "󰤨 {essid}";
          "format-ethernet" = " wired";
          "format-disconnected" = "󰤭";
          "on-click" = "bash ~/.config/waybar/scripts/rofi-wifi-menu.sh";
        };

        "pulseaudio" = {
          "format" = "{icon} {volume}%";
          "format-bluetooth" = "  {volume}%";
          "format-bluetooth-muted" = "";
          "format-muted" = "󰝟";
          "format-icons" = {
            "headphone" = "";
            "hands-free" = "";
            "headset" = "";
            "phone" = "";
            "portable" = "";
            "car" = "";
            "default" = [
              ""
              ""
              ""
            ];
          };
          "on-click" = "pavucontrol";
        };

        "bluetooth" = {
          "on-click" = "~/.config/waybar/scripts/rofi-bluetooth &";
          "format" = " {status} {num_connections}";
        };

        "battery" = {
          "bat" = "BAT1";
          "adapter" = "ADP0";
          "interval" = 60;
          "states" = {
            "warning" = 30;
            "critical" = 15;
          };
          "max-length" = 20;
          "format" = "{icon} {capacity}%";
          "format-warning" = "{icon} {capacity}%";
          "format-critical" = "{icon} {capacity}%";
          "format-charging" = "<span font-family='Font Awesome 6 Free'></span> {capacity}%";
          "format-plugged" = "  {capacity}%";
          "format-alt" = "{icon} {time}";
          "format-full" = "  {capacity}%";
          "format-icons" = [
            " "
            " "
            " "
            " "
            " "
          ];
        };

        "disk" = {
          "interval" = 30;
          "format" = "{free} / {total}";
          "path" = "/";
        };

        "custom/spotify" = {
          "exec" = "python3 ~/.config/waybar/scripts/mediaplayer.py --player spotify";
          "format" = "{}  ";
          "return-type" = "json";
          "on-click" = "playerctl play-pause";
          "on-double-click-right" = "playerctl next";
          "on-scroll-down" = "playerctl previous";
        };

        "custom/power-menu" = {
          "format" = " <span color='#6a92d7'>⏻ </span>";
          "on-click" = "bash ~/.config/waybar/scripts/power-menu/powermenu.sh";
        };

        "custom/launcher" = {
          "format" = " <span color='#6a92d7'></span>";
          "on-click" = "rofi -show drun";
        };

      };
    };
    style = ''
      * {
          /* `otf-font-awesome` is required to be installed for icons */
          /* font-family: JetBrainsMono Nerd Font Mono; */
          font-family: VictorMono Nerd Font;
          font-size: 14px;
      }

      window#waybar {
          background-color: rgba(10, 10, 10, 10);
          color: #ffffff;
          transition-property: background-color;
          transition-duration: 0.5s;
          border-top: 8px transparent;
          border-radius: 0px;
          transition-duration: 0.5s;
          margin: 16px 16px;
      }

      #custom-launcher {
          margin-left: 5px;
          margin-top: 3px;
          margin-bottom: 3px;

          background-color: #1b242b;
          color: #6a92d7;
          border-radius: 7.5px;
      }

      #custom-power-menu {
          margin-left: 5px;
          margin-top: 3px;
          margin-bottom: 3px;
          margin-right: 5px;

          border-radius: 9.5px;
          background-color: #1b242b;
          border-radius: 7.5px;
      }

      window#waybar.hidden {
          opacity: 0.2;
      }

      #workspaces button {
          padding: 0 5px;
          color: #7984A4;
          background-color: transparent;
          box-shadow: inset 0 -3px transparent;
          border: none;
          border-radius: 0;
      }

      #workspaces button.focused {
          color: #bf616a;
      }

      #workspaces button.active {
          color: #6a92d7;
      }

      #workspaces button.urgent {
          background-color: #eb4d4b;
      }

      #window {
          color: #64727d;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #disk,
      #temperature,
      #backlight,
      #network,
      #pulseaudio,
      #custom-media,
      #tray,
      #mode,
      #idle_inhibitor,
      #mpd,
      #bluetooth,
      #custom-hyprPicker,
      #custom-power-menu,
      #custom-spotify,
      #custom-weather {
          padding: 0 10px;
          color: #e5e5e5;
          border-radius: 9.5px;
      }

      #window,
      #workspaces {
          margin: 0 4px;
          border-radius: 7.8px;
      }

      #cpu {
          color: #fb958b;
      }

      #memory {
          color: #ebcb8b;
      }

      #custom-weather.severe {
          color: #eb937d;
      }

      #custom-weather.sunnyDay {
          color: #c2ca76;
      }

      #custom-weather.clearNight {
          color: #cad3f5;
      }

      #custom-weather.cloudyFoggyDay,
      #custom-weather.cloudyFoggyNight {
          color: #c2ddda;
      }

      #custom-weather.rainyDay,
      #custom-weather.rainyNight {
          color: #5aaca5;
      }

      #custom-weather.showyIcyDay,
      #custom-weather.snowyIcyNight {
          color: #d6e7e5;
      }

      #custom-weather.default {
          color: #dbd9d8;
      }

      .modules-left>widget:first-child>#workspaces {
          margin-left: 0;
      }

      .modules-right>widget:last-child>#workspaces {
          margin-right: 0;
      }

      #pulseaudio {
          color: #7d9bba;
      }

      #backlight {
          color: #8fbcbb;
      }

      #clock {
          color: #c8d2e0;
      }

      #battery {
          color: #c0caf5;
      }

      #battery.charging,
      #battery.full,
      #battery.plugged {
          color: #26a65b;
      }

      @keyframes blink {
          to {
              background-color: rgba(30, 34, 42, 0.5);
              color: #abb2bf;
          }
      }

      #battery.critical:not(.charging) {
          color: #f53c3c;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }

      label:focus {
          background-color: #000000;
      }

      #disk {
          color: #73d0ff;
      }

      #bluetooth {
          color: #707d9d;
      }

      #bluetooth.disconnected {
          color: #f53c3c;
      }

      #network {
          color: #b48ead;
      }

      #network.disconnected {
          color: #f53c3c;
      }

      #custom-media {
          background-color: #66cc99;
          color: #2a5c45;
          min-width: 100px;
      }

      #custom-media.custom-spotify {
          background-color: #66cc99;
      }

      #custom-media.custom-vlc {
          background-color: #ffa000;
      }

      #temperature {
          background-color: #f0932b;
      }

      #temperature.critical {
          background-color: #eb4d4b;
      }

      #tray>.passive {
          -gtk-icon-effect: dim;
      }

      #tray>.needs-attention {
          -gtk-icon-effect: highlight;
          background-color: #eb4d4b;
      }

      #idle_inhibitor {
          background-color: #2d3436;
      }

      #idle_inhibitor.activated {
          background-color: #ecf0f1;
          color: #2d3436;
      }

      #mpd {
          color: #2a5c45;
      }

      #mpd.disconnected {
          color: #f53c3c;
      }

      #mpd.stopped {
          color: #90b1b1;
      }

      #mpd.paused {
          color: #51a37a;
      }

      #language {
          background: #00b093;
          color: #740864;
          padding: 0 5px;
          margin: 0 5px;
          min-width: 16px;
      }

      #keyboard-state {
          background: #97e1ad;
          color: #000000;
          padding: 0 0px;
          margin: 0 5px;
          min-width: 16px;
      }

      #keyboard-state>label {
          padding: 0 5px;
      }

      #custom-spotify {
          padding: 0 10px;
          margin: 0 4px;
          color: #abb2bf;
      }

      #keyboard-state>label.locked {
          background: rgba(0, 0, 0, 0.2);
      }
    '';
  };

  home.packages = with pkgs; [
    dunst
    gsettings-desktop-schemas
    wlr-randr
    wtype
    wl-clipboard
    hyprland-protocols
    hyprpicker
    xdg-utils
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    pamixer
    pavucontrol
    swayidle
    swaylock
    rofi-wayland
    polkit_gnome
    libva-utils
    grimblast
  ];

}
