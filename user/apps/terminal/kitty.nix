{ pkgs-unstable, ... }:

# Colors, alpha and font come from stylix.targets.kitty (user/theme.nix), which
# includes a generated base16 theme. The raw kitty.conf is still owned here for
# everything non-color: this file is loaded after the include, so deleting the
# color_* / background / foreground keys stops it overriding Stylix.
{
  programs.kitty = {
    enable = true;
    package = pkgs-unstable.kitty;
    extraConfig = builtins.readFile ./configs/kitty/kitty.conf;
  };
}
