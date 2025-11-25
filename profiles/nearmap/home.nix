{ pkgs, ... }:
{
  imports = [
    ../shared.nix
    ../../user/shell/sh.nix # Fish config
    ../../user/shell/tui.nix # Useful cli/tui apps
    ../../user/apps/git/git.nix # My git config
    ../../user/lang/nix/nix.nix # nix tools
    ../../user/lang/shell/shell.nix # shell tools
    ../../user/apps/fileman/yazi.nix
    ../../user/apps/terminal/myvim.nix
    ../../user/apps/terminal/helix-fork.nix
    ../../user/apps/terminal/curl.nix # network request cli/tuis
    # TODO: Kitty conf toggled by OS
    ../../user/lang/go/go.nix # go tools
    # ../../user/wm/hyprspace
  ];

  home.packages = with pkgs; [
    # cachix
    diff-so-fancy
    git

    sops
  ];
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  xdg = {
    enable = true;
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
}
