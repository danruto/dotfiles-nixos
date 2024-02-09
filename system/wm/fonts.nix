{ pkgs, ... }:

{
  fonts.fontconfig.enable = true;
  fonts.fontDir.enable = true;

  fonts.packages = with pkgs; [
    powerline
    inconsolata
    inconsolata-nerdfont
    iosevka
    font-awesome
    ubuntu_font_family
    terminus_font
		d2coding
    font-awesome
    jetbrains-mono
    d2coding
    nerdfonts
    agave
  ];

}
