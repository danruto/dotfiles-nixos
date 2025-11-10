{ lib, pkgs, ... }:
{
  imports = [
    ../waybar/waybar.nix
  ];

  wayland.windowManager.sway = {
    enable = true;
    config = rec {
      modifier = "Mod4"; # Super key
      terminal = "foot";
      menu = "vicinae toggle";

      startup = [
        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }
        { command = "${lib.getExe pkgs.mako}"; }
        { command = "${lib.getExe pkgs.waybar}"; }
      ];

      input = {
        "*" = {
          xkb_layout = "us";
        };
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "disabled";
          dwt = "enabled";
        };
      };

      output = {
        "*" = {
          bg = "#1e1e1e solid_color";
        };
      };

      gaps = {
        inner = 5;
        outer = 5;
      };

      keybindings =
        let
          mod = modifier;
        in
        lib.mkOptionDefault {
          # Application shortcuts
          "${mod}+Return" = "exec ${terminal}";
          "${mod}+q" = "kill";
          "${mod}+r" = "exec ${menu}";
          "Mod1+space" = "exec ${menu}"; # Alt+space for vicinae
          "${mod}+Shift+c" = "reload";
          "${mod}+Shift+e" = "exec swaynag -t warning -m 'Exit sway?' -B 'Yes' 'swaymsg exit'";

          # Window focus
          "${mod}+h" = "focus left";
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";
          "${mod}+l" = "focus right";

          # Move windows
          "${mod}+Shift+h" = "move left";
          "${mod}+Shift+j" = "move down";
          "${mod}+Shift+k" = "move up";
          "${mod}+Shift+l" = "move right";

          # Workspaces
          "${mod}+1" = "workspace number 1";
          "${mod}+2" = "workspace number 2";
          "${mod}+3" = "workspace number 3";
          "${mod}+4" = "workspace number 4";
          "${mod}+5" = "workspace number 5";
          "${mod}+6" = "workspace number 6";
          "${mod}+7" = "workspace number 7";
          "${mod}+8" = "workspace number 8";
          "${mod}+9" = "workspace number 9";

          # Move windows to workspaces
          "${mod}+Shift+1" = "move container to workspace number 1";
          "${mod}+Shift+2" = "move container to workspace number 2";
          "${mod}+Shift+3" = "move container to workspace number 3";
          "${mod}+Shift+4" = "move container to workspace number 4";
          "${mod}+Shift+5" = "move container to workspace number 5";
          "${mod}+Shift+6" = "move container to workspace number 6";
          "${mod}+Shift+7" = "move container to workspace number 7";
          "${mod}+Shift+8" = "move container to workspace number 8";
          "${mod}+Shift+9" = "move container to workspace number 9";

          # Layout
          "${mod}+b" = "splith";
          "${mod}+v" = "splitv";
          "${mod}+s" = "layout stacking";
          "${mod}+w" = "layout tabbed";
          "${mod}+e" = "layout toggle split";
          "${mod}+f" = "fullscreen toggle";
          "${mod}+Shift+space" = "floating toggle";
          "${mod}+space" = "focus mode_toggle";

          # Screenshots
          "${mod}+Shift+s" = "exec grim -g \"$(slurp)\" - | wl-copy";

          # Scratchpad
          "${mod}+Shift+minus" = "move scratchpad";
          "${mod}+minus" = "scratchpad show";
        };

      bars = [ ]; # We'll use waybar instead
    };

    extraConfig = ''
      # Additional sway config
      default_border pixel 2
      default_floating_border pixel 2

      # Colors
      client.focused          #4c7899 #285577 #ffffff #2e9ef4 #285577
      client.focused_inactive #333333 #5f676a #ffffff #484e50 #5f676a
      client.unfocused        #333333 #222222 #888888 #292d2e #222222
      client.urgent           #2f343a #900000 #ffffff #900000 #900000
    '';

    systemd.enable = true;
    wrapperFeatures.gtk = true;
    xwayland = true;
  };

  home.packages = with pkgs; [
    mako
    wl-clipboard
    grim
    slurp
    wf-recorder
    polkit_gnome
  ];
}
