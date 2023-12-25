{ config, lib, pkgs, stdenv, fetchurl, stylix, username, email, dotfilesDir, theme, wm, editor, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = username;
  home.homeDirectory = "/home/"+username;

  programs.home-manager.enable = true;

  imports = [
              stylix.homeManagerModules.stylix
              ../../user/shell/sh.nix # My zsh and bash config
              ../../user/shell/cli-collection.nix # Useful CLI apps
              ../../user/apps/git/git.nix # My git config
              ../../user/style/stylix.nix # Styling and themes for my apps
              ../../user/lang/cc/cc.nix # C and C++ tools
            ];

  home.stateVersion = "22.11"; # Please read the comment before changing.

  home.packages = with pkgs; [
    # Core
    fish
    git

    # Various dev packages
    texinfo
    libffi zlib
    nodePackages.ungit
  ];

  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    music = "${config.home.homeDirectory}/media/music";
    videos = "${config.home.homeDirectory}/media/videos";
    pictures = "${config.home.homeDirectory}/media/pictures";
    templates = "${config.home.homeDirectory}/templates";
    download = "${config.home.homeDirectory}/downloads";
    documents = "${config.home.homeDirectory}/documents";
    desktop = null;
    publicShare = null;
    extraConfig = {
      XDG_DOTFILES_DIR = "${config.home.homeDirectory}/.dotfiles";
      XDG_ARCHIVE_DIR = "${config.home.homeDirectory}/archive";
      XDG_ORG_DIR = "${config.home.homeDirectory}/org";
      XDG_BOOK_DIR = "${config.home.homeDirectory}/media/books";
    };
  };
  xdg.mime.enable = true;
  xdg.mimeApps.enable = true;

  home.sessionVariables = {
    EDITOR = editor;
  };

}
