{ pkgs, username, vicinae, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = username;
  home.homeDirectory = "/home/" + username;

  programs.home-manager.enable = true;

  imports = [
    vicinae.homeManagerModules.default

    # stylix.homeManagerModules.stylix
    # ../../user/style/stylix.nix # Styling and themes for my apps
    ../shared.nix # Shared home configurations
    ../../user/shell/sh.nix # Fish config
    ../../user/shell/tui.nix # Useful cli/tui apps
    ../../user/apps/git/git.nix # My git config
    ../../user/lang/cc/cc.nix # C and C++ tools
    ../../user/lang/rust/rust.nix # Rust tools
    ../../user/lang/typescript/typescript.nix # typescript tools
    ../../user/lang/go/go.nix # go tools
    ../../user/lang/lua/lua.nix # lua tools
    ../../user/lang/nix/nix.nix # nix tools
    ../../user/lang/shell/shell.nix # shell tools
    # ../../user/wm/sway/sway.nix # wm
    ../../user/apps/terminal/helix-fork.nix
    ../../user/apps/terminal/curl.nix # network request cli/tuis
    ../../user/apps/terminal/myvim.nix
    ../../user/apps/terminal/foot.nix
    ../../user/apps/browser/ff.nix
    ../../user/apps/fileman/cosmic.nix
    ../../user/apps/fileman/yazi.nix
  ];

  services.vicinae = {
    enable = true; # default: false
  };

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
