{ lib, pkgs, pkgs-unstable, config, ... }:
let
  statusbar = pkgs.writeShellScriptBin "statusbar" (builtins.readFile ./statusbar.sh);
  switch = pkgs.writeShellScriptBin "switch" (builtins.readFile ./switch.sh);
  xdg = pkgs.writeShellScriptBin "xdg" (builtins.readFile ./xdg.sh);
in
{

  imports = [
    ../waybar/waybar.nix
    # Shared DankMaterialShell bar (same config as Niri). Disables waybar
    # while enabled; Hyprland keeps waybar+dunst as a DMS-less fallback.
    ../dms.nix
  ];

  programs.waybar.enable = lib.mkIf config.programs.dank-material-shell.enable (lib.mkForce false);

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
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
        "${lib.getExe xdg}"
        # "${lib.getExe statusbar}" # waybar is handled by systemd service
        # "${lib.getExe pkgs.waybar}"
      ]
      # DMS owns notifications + polkit when enabled; otherwise fall back to
      # the old dunst + polkit-gnome stack so Hyprland works DMS-less.
      ++ lib.optional config.programs.dank-material-shell.enable "dms run"
      ++ lib.optionals (!config.programs.dank-material-shell.enable) [
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "${lib.getExe pkgs.dunst}"
      ];

      env = [
        "XCURSOR_SIZE,24"
      ];

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
        # Follows the Stylix palette so a theme switch recolors borders.
        "col.active_border" = with config.lib.stylix.colors; "rgba(${base0D}ee) rgba(${base0A}ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";

        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
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
      };

      gestures = {
      };


      bindm = [
        # Move/resize windows with mainMod + LMB/RMB and dragging
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      bind = [
        "$mainMod, Return, exec, foot"
        "$mainMod, Q, killactive,"
        "$mainMod, E, exec, nemo"
        "$mainMod, V, togglefloating,"
        "$mainMod, R, exec, dms ipc call spotlight toggle"
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

    # Runtime border colors, rewritten by scripts/theme-render per switch.
    extraConfig = ''
      source = ${config.home.homeDirectory}/.local/state/theme/live/hyprland.conf
    '';
    xwayland = { enable = true; };
    systemd.enable = true;
  };

  # programs.waybar.package = pkgs.unstable.waybar.overrideAttrs (oldAttrs: {
  #   postPatch = ''
  #     # use hyprctl to switch workspaces
  #     # sed -i 's/zext_workspace_handle_v1_activate(workspace_handle_);/const std::string command = "hyprworkspace " + name_;\n\tsystem(command.c_str());/g' src/modules/wlr/workspace_manager.cpp
  #     # sed -i 's/gIPC->getSocket1Reply("dispatch workspace " + std::to_string(id()));/const std::string command = "hyprworkspace " + std::to_string(id());\n\tsystem(command.c_str());/g' src/modules/hyprland/workspaces.cpp
  #   '';
  # });


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
    polkit_gnome
    libva-utils
    grimblast
  ];

}
