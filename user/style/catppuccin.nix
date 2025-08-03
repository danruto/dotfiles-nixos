{ catppuccin, ... }:

{
  imports = [
    catppuccin.homeModules.catppuccin
    {
      catppuccin.flavor = "mocha";
      # catppuccin.gtk.enable = true;
      catppuccin.ghostty.enable = true;
      # catppuccin.floorp.profiles.default.enable = true;
      catppuccin.foot.enable = true;
    }
  ];

  # home.sessionVariables.GTK_THEME = "";
}
