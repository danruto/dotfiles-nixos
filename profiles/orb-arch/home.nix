{ pkgs, editor, ... }:

{
  programs.home-manager.enable = true;

  imports = [
    ../shared.nix
    ../../user/shell/sh.nix
    ../../user/shell/tui.nix
    ../../user/apps/git/git.nix
    ../../user/apps/terminal/helix-fork.nix
    ../../user/apps/fileman/yazi.nix
  ];

  home.username = "danruto";
  home.homeDirectory = "/home/danruto";
  home.stateVersion = "25.05";

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

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };
}
