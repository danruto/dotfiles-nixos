{
  services.skhd = {
    enable = true;
    skhdConfig = ''
      # Default mode
      :: default

      cmd - return : /Applications/Kitty.app/Contents/MacOS/kitty --single-instance -d ~ &> /dev/null

      # balance size of windows
      shift + ctrl - 0 : yabai -m space --balance

      # make floating window fill screen
      shift + ctrl - 0x7E : yabai -m window --grid 1:1:0:0:1:1

      # make floating window fill left-half of screen
      shift + ctrl - 0x7B : yabai -m window --grid 1:2:0:0:1:1

      # make floating window fill right-half of screen
      shift + ctrl - 0x7C : yabai -m window --grid 1:2:1:0:1:1

      cmd + alt - n : yabai -m space --create;\
                id=$(yabai -m query --displays --display | grep "spaces");\
                yabai -m space --focus $(echo $id:10:$#id-10)

      # move window
      shift + ctrl - z : yabai -m window --move rel:-20:0
      shift + ctrl - x : yabai -m window --move rel:0:20
      shift + ctrl - c : yabai -m window --move rel:0:-20
      shift + ctrl - v : yabai -m window --move rel:20:0

      # increase window size
      shift + ctrl - a : yabai -m window --resize left:-20:0
      shift + ctrl - s : yabai -m window --resize bottom:0:20
      # shift + ctrl - w : yabai -m window --resize top:0:-20
      shift + ctrl - d : yabai -m window --resize right:20:0

      # decrease window size
      shift + cmd - a : yabai -m window --resize left:20:0
      shift + cmd - s : yabai -m window --resize bottom:0:-20
      # shift + cmd - w : yabai -m window --resize top:0:20
      shift + cmd - d : yabai -m window --resize right:-20:0

      # set insertion point in focused container
      ctrl + alt - h : yabai -m window --insert west
      ctrl + alt - j : yabai -m window --insert south
      ctrl + alt - k : yabai -m window --insert north
      ctrl + alt - l : yabai -m window --insert east

      # rotate tree
      alt - r : yabai -m space --rotate 90

      # mirror tree y-axis
      alt - y : yabai -m space --mirror y-axis

      # mirror tree x-axis
      alt - x : yabai -m space --mirror x-axis

      # toggle desktop offset
      alt - a : yabai -m space --toggle padding; yabai -m space --toggle gap

      # toggle window parent zoom
      alt - d : yabai -m window --toggle zoom-parent

      # toggle window fullscreen zoom
      alt - f : yabai -m window --toggle zoom-fullscreen

      # toggle window native fullscreen
      shift + alt - f : yabai -m window --toggle native-fullscreen

      # toggle window border
      shift + alt - b : yabai -m window --toggle border

      # toggle window split type
      alt - e : yabai -m window --toggle split

      # float / unfloat window and center on screen
      alt - t : yabai -m window --toggle float;\
                yabai -m window --grid 4:4:0:0:4:4

      # toggle sticky
      alt - s : yabai -m window --toggle sticky

      # toggle sticky, topmost and resize to picture-in-picture size
      alt - p : yabai -m window --toggle sticky;\
                yabai -m window --toggle topmost;\
                yabai -m window --grid 5:5:4:0:1:1

      # change layout of desktop
      ctrl + alt - a : yabai -m space --layout bsp
      ctrl + alt - d : yabai -m space --layout float
      ctrl + alt - s : yabai -m space --layout stack

      # SHELL=/bin/bash skhd
    '';
  };
}

