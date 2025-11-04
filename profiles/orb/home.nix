{ pkgs, editor, ... }:

{
  programs.home-manager.enable = true;

  imports = [
    # stylix.homeManagerModules.stylix
    # ../../user/style/stylix.nix # Styling and themes for my apps
    ../shared.nix # Shared home configurations
    ../../user/shell/sh.nix # Fish config
    ../../user/shell/tui.nix # Useful cli/tui apps
    ../../user/apps/git/git.nix # My git config
    ../../user/apps/terminal/myvim.nix
    ../../user/apps/terminal/helix-fork.nix
    ../../user/lang/cc/cc.nix # C and C++ tools
    ../../user/lang/rust/rust.nix # Rust tools
    ../../user/lang/typescript/typescript.nix # typescript tools
    ../../user/lang/go/go.nix # go tools
    ../../user/lang/lua/lua.nix # lua tools
    ../../user/lang/nix/nix.nix # nix tools
    ../../user/lang/shell/shell.nix # shell tools
    ../../user/apps/fileman/yazi.nix
  ];

  home.stateVersion = "25.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    # Core
    git

    # Various dev packages
    texinfo
    libffi
    zlib
    nodePackages.ungit
  ];

  # xdg.enable = true;
  # xdg.userDirs = {
  #   enable = true;
  #   createDirectories = true;
  #   music = "${config.home.homeDirectory}/media/music";
  #   videos = "${config.home.homeDirectory}/media/videos";
  #   pictures = "${config.home.homeDirectory}/media/pictures";
  #   templates = "${config.home.homeDirectory}/templates";
  #   download = "${config.home.homeDirectory}/downloads";
  #   documents = "${config.home.homeDirectory}/documents";
  #   desktop = null;
  #   publicShare = null;
  #   extraConfig = {
  #     XDG_DOTFILES_DIR = "${config.home.homeDirectory}/.dotfiles";
  #     XDG_ARCHIVE_DIR = "${config.home.homeDirectory}/archive";
  #     XDG_ORG_DIR = "${config.home.homeDirectory}/org";
  #     XDG_BOOK_DIR = "${config.home.homeDirectory}/media/books";
  #   };
  # };
  # xdg.mime.enable = true;
  # xdg.mimeApps.enable = true;

  home.sessionVariables = {
    EDITOR = editor;
  };

  programs.starship.enable = true;
  programs.starship.settings = {
    gcloud.disabled = true;
    kubernetes.disabled = false;
    git_branch.style = "242";
    directory.style = "bold blue dimmed";
    directory.truncate_to_repo = false;
    directory.truncation_length = 8;
    python.disabled = true;
    ruby.disabled = true;
    hostname.ssh_only = false;
    hostname.style = "bold green";
    memory_usage.disabled = false;
    memory_usage.threshold = -1;
  };

  programs.nix-index =
    {
      enable = true;
      enableFishIntegration = true;
    };
}
