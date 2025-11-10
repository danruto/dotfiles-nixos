{ pkgs, ... }:

{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    powerline
    iosevka
    font-awesome
    terminus_font
    font-awesome
    jetbrains-mono
    iosevka-comfy.comfy
    nerd-fonts.noto
    nerd-fonts.hack
    nerd-fonts.agave
    nerd-fonts.ubuntu-mono
    nerd-fonts.zed-mono
    nerd-fonts.d2coding
    nerd-fonts.blex-mono
    nerd-fonts.space-mono
    nerd-fonts.victor-mono
    nerd-fonts.adwaita-mono
    nerd-fonts.departure-mono
    nerd-fonts.caskaydia-cove
    nerd-fonts.inconsolata
  ];

}
