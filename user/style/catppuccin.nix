{ catppuccin, ... }:

{
  imports = [
    catppuccin.homeModules.catppuccin
    {
      catppuccin.flavor = "mocha";
      catppuccin.accent = "mauve";
      catppuccin.ghostty.enable = true;
      # catppuccin.foot.enable = true;
      # catppuccin.alacritty.enable = true;
      catppuccin.kitty.enable = true;
      # catppuccin.helix.enable = true;
      catppuccin.bat.enable = true;
      # catppuccin.zellij.enable = true;
      # Let stylix handle GTK theming for consistency
      # catppuccin.gtk.enable = false;
    }
  ];
}
