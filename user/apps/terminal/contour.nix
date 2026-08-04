{ ... }:

# Contour itself comes from homebrew (`brew install --cask contour`) and is left
# unmanaged, like ghostty/aerospace on the darwin hosts. This module only places
# the config, verbatim, from ./configs/contour/.
#
# Notes for other machines:
#   - font is "D2KodingLigature Nerd Font Mono" (cask: font-d2coding-nerd-font).
#     Nerd Fonts renamed the patched family from D2Coding* to D2Koding*.
#   - show_title_bar: false makes AeroSpace float the window (frameless Qt window
#     trips its dialog heuristic); the on-window-detected rule in
#     user/wm/aerospace/aerospace.toml forces it back to tiling.
#   - `show_title_bar` only applies on profile activation, so it needs a full ⌘Q,
#     not just closing the window. status_line changes reload live.
{
  home.file.".config/contour/contour.yml".source = ./configs/contour/contour.yml;
}
