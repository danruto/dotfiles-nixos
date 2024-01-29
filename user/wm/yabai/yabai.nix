{ pkgs, ... }:

# https://github.com/LnL7/nix-darwin/blob/master/modules/services/yabai/default.nix
{
  services.yabai = {
    enable = true;
    package = pkgs.unstable.yabai;
    enableScriptingAddition = true;
    config = {
      # Binary space partitioning layout
      layout = "bsp";
      # When focusing a window, put the mouse at its center
      mouse_follows_focus = "off";
      # Automatically focus the window under the mouse
      focus_follows_mouse = "off";
      # New window spawns to the right if vertical split, or bottom if
      # horizontal split
      window_placement = "second_child";
      # Disable opacity for windows
      window_opacity = "off";
      window_topmost = "off";
      # Draw shadow for windows, window_border has been removed
      window_shadow = "on";
      # Size of the gap that separates windows
      window_gap = 2;
      # Padding added around the sides of a space
      top_padding = 8;
      bottom_padding = 2;
      left_padding = 2;
      right_padding = 2;
      # Add padding for external status bar
      external_bar = "main:49:0";

      active_window_border_color = "0xfff29718";
      normal_window_border_color = "0xffb3b1ad";
      insert_window_border_color = "0xff4d5566";

      active_window_opacity = 1.0;
      normal_window_opacity = 0.9;
      split_ratio = 0.5;

      auto_balance = "off";
      window_animation_duration = 0.25;
    };
    extraConfig = ''
      yabai -m space 1 --label chat
      yabai -m space 2 --label web
      yabai -m space 3 --label dev
      yabai -m space 4 --label misc
      yabai -m space 5 --label misc2

      yabai -m config --space 5 layout             stack
      yabai -m config --space 4 layout             float
      yabai -m config --space 2 auto_balance on


      yabai -m rule --add app="Marta" space=^4
      yabai -m rule --add app="Notion" space=^4
      yabai -m rule --add app="Discord" space=^1
      yabai -m rule --add app="Slack" space=^1
      yabai -m rule --add app="Spark" space=^1
      yabai -m rule --add app="Home" space=^1

      yabai -m rule --add app="^System Settings$" manage=off
      yabai -m rule --add app="^System Information$" label="^About This Mac$" manage=off
      yabai -m rule --add app="Boot Camp Assistant" manage=off
      yabai -m rule --add app="Simulator" manage=off
      yabai -m rule --add app="IINA" manage=off
      yabai -m rule --add app="^1Password" manage=off
      yabai -m rule --add app="^Riot Client" manage=off
      yabai -m rule --add app="^League of Legends" manage=off
      yabai -m rule --add app="^(LuLu|Vimac|Calculator|VLC|System Preferences|zoom.us|Photo Booth|Archive Utility|Python|LibreOffice)$" manage=off
      yabai -m rule --add label="Finder" app="^Finder$" title="(Co(py|nnect)|Move|Info|Pref)" manage=off
      yabai -m rule --add label="Alfred" app="^Alfred$" manage=off
      yabai -m rule --add label="Safari" app="^Safari$" title="^(General|(Tab|Password|Website|Extension)s|AutoFill|Se(arch|curity)|Privacy|Advance)$" manage=off
      yabai -m rule --add label="System Preferences" app="^System Preferences$" title=".*" manage=off
      yabai -m rule --add label="App Store" app="^App Store$" manage=off
      yabai -m rule --add label="Activity Monitor" app="^Activity Monitor$" manage=off
      yabai -m rule --add label="Calculator" app="^Calculator$" manage=off
      yabai -m rule --add label="Dictionary" app="^Dictionary$" manage=off
      yabai -m rule --add label="Software Update" title="Software Update" manage=off
      yabai -m rule --add label="About This Mac" app="System Information" title="About This Mac" manage=off
      yabai -m rule --add label="Select file to save to" app="^Inkscape$" title="Select file to save to" manage=off
      yabai -m rule --add label="PDFScroller" manage=off
      yabai -m rule --add label="WezTerm" manage=off
      yabai -m rule --add label="wezterm-gui" manage=off


      yabai -m signal --add event=window_destroyed action="yabai -m query --windows --window &> /dev/null || yabai -m window --focus mouse"
      yabai -m signal --add event=application_terminated action="yabai -m query --windows --window &> /dev/null || yabai -m window --focus mouse"
      # Load scripting addition
      yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
      yabai -m signal --add event=window_focused action="sketchybar --trigger window_focus"
      sudo yabai --load-sa
    '';
  };
}

