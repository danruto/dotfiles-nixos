{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    alacritty
  ];
  programs.alacritty.enable = true;

  programs.alacritty.settings = {
    window.opacity = lib.mkForce 0.65;
    window.decorations = "none";
    font.size = 11.0;
    font.normal.family = "D2Coding";
    colors.draw_bold_text_with_bright_colors = true;
    window.padding.x = 5;
    window.padding.y = 5;
  };
}
