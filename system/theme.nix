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

    base16Scheme = dir + "/${theme}.yaml";
    polarity = read "polarity.txt";
    image = pkgs.fetchurl {
      url = read "backgroundurl.txt";
      hash = read "backgroundsha256.txt";
    };
  };
}
