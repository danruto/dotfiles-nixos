{ pkgs, ... }:

# Config is the verbatim file from ./configs/alacritty/, not `programs.alacritty.settings`.
# Both write ~/.config/alacritty/alacritty.toml, so enabling the program module here
# would collide with the raw file.
{
  home.packages = [ pkgs.alacritty ];

  home.file.".config/alacritty/alacritty.toml".source = ./configs/alacritty/alacritty.toml;
}
