{ pkgs, editor, ... }:

{
  programs.home-manager.enable = true;

  imports = [
    ../shared.nix
    ../../user/apps/ai/llm.nix
    ../../user/shell/sh.nix
    ../../user/shell/tui.nix
    ../../user/apps/git/git.nix
    ../../user/apps/terminal/myvim.nix
    # ../../user/apps/terminal/helix-fork.nix
    ../../user/apps/terminal/helix.nix
    ../../user/apps/fileman/yazi.nix
    ../../user/lang/shell/shell.nix
  ];

  home.username = "danruto";
  home.homeDirectory = "/home/danruto";
  home.stateVersion = "25.05";

  home.sessionVariables = {
    EDITOR = editor;
    TERM = "xterm-256color";
  };

  programs.fish.shellInit = ''
    fish_add_path --prepend ~/.local/state/nix/profiles/home-manager/home-path/bin
    fish_add_path --prepend ~/.nix-profile/bin
  '';

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
