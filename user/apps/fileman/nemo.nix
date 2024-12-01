{ pkgs, ... }:
let
  catppuccin_name = "Catppuccin-Mocha-Compact-Sapphire-Dark";
  catppuccin = pkgs.catppuccin-gtk.override {
    accents = [ "sapphire" ]; # You can specify multiple accents here to output multiple themes
    size = "compact";
    tweaks = [ "rimless" "black" ]; # You can also specify multiple tweaks here
    variant = "mocha";
  };
in
{
  home.packages = with pkgs; [
    nemo-with-extensions
    dbus
    samba
    gvfs
  ];

  gtk = {
    enable = true;
    theme = {
      name = catppuccin_name;
      package = catppuccin;
      # package = pkgs.flat-remix-gtk;
    };
    cursorTheme = {
      name = "Catppuccin-Mocha-Dark-Cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
    };
  };

  home.sessionVariables.GTK_THEME = catppuccin_name;

  #home.file.".config/gtk-4.0/gtk.css".source = "${catppuccin}/share/themes/${catppuccin_name}/gtk-4.0/gtk.css";
  home.file.".config/gtk-4.0/gtk-dark.css".source = "${catppuccin}/share/themes/${catppuccin_name}/gtk-4.0/gtk-dark.css";

  home.file.".config/gtk-4.0/assets" = {
    recursive = true;
    source = "${catppuccin}/share/themes/${catppuccin_name}/gtk-4.0/assets";
  };

  programs.yazi.enable = true;
}

