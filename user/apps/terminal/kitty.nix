{ pkgs-unstable, ... }:

# Config is the verbatim file from ./configs/kitty/, not `programs.kitty.settings`.
# Both write ~/.config/kitty/kitty.conf, so enabling the program module here
# would collide with the raw file.
{
  home.packages = [ pkgs-unstable.kitty ];

  home.file.".config/kitty/kitty.conf".source = ./configs/kitty/kitty.conf;
}
