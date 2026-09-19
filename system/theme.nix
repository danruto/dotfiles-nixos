# Stylix: one base16 palette in themes/<theme>/ drives colours, fonts and the
# wallpaper. Targets are opt-in — autoEnable clobbers the hand-written app
# configs under user/ (gtk.theme, helix theme, the raw kitty.conf, ...).
{ lib, pkgs, theme, ... }:
let
  dir = ../themes + "/${theme}";
  read = f: lib.trim (builtins.readFile (dir + "/${f}"));
in
{
  stylix = {
    enable = true;
    autoEnable = false;

    # Pin the font family back to what this repo already used; otherwise Stylix
    # defaults to a different sans/mono pair and recolors every target away
    # from D2Coding.
    fonts.monospace = {
      name = "D2KodingLigature Nerd Font";
      package = pkgs.d2coding;
    };
    fonts.sansSerif = {
      name = "D2KodingLigature Nerd Font";
      package = pkgs.d2coding;
    };
    fonts.sizes = {
      terminal = 14;
      applications = 12;
    };

    base16Scheme = dir + "/${theme}.yaml";
    polarity = read "polarity.txt";
  } // lib.optionalAttrs (builtins.pathExists (dir + "/backgroundurl.txt")) {
    # Only some themes ship a curated background; theme-render already treats
    # it as optional, so a theme without one must still evaluate.
    image = pkgs.fetchurl {
      url = read "backgroundurl.txt";
      hash = read "backgroundsha256.txt";
    };
  };
}
