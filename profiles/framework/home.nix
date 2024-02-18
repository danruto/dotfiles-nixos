{ pkgs, ... }: {

  home.username = "danruto";
  home.homeDirectory = "/home/danruto";

  # programs.home-manager.enable = true;

  imports = [
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
    ../../user/apps/terminal/lazyvim.nix
    ../../user/apps/terminal/helix.nix
    ../../user/apps/terminal/alacritty.nix
    ../../user/apps/terminal/kitty.nix
    ../../user/wm/hyprland/hyprland.nix
    ../../user/apps/browser/brave.nix
    ../../user/apps/fileman/nemo.nix
    ../../user/apps/gui/gui.nix
    ../../user/apps/networking/wireguard.nix
    ../../user/apps/security/1password.nix
    ../../system/hardware/monitor.nix
    ../../user/hardware/keyboard.nix
  ];

  home.packages = with pkgs; [
    cachix
    diff-so-fancy
    git
  ];
  home.stateVersion = "23.11";

  programs.direnv = {
    enable = true;
    config = {
      load_dotenv = true;
    };
  };
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

  home.file.".config/rofi/config.rasi".source = ../../user/config/rofi.rasi;

  programs.nix-index =
    {
      enable = true;
      enableFishIntegration = true;
    };

  # programs.fish.enable = true;
  # programs.zsh.enable = true;
}

