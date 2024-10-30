{ pkgs, ... }: {

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
    ../../user/lang/zig/zig.nix # zig tools
    ../../user/lang/nix/nix.nix # nix tools
    ../../user/lang/shell/shell.nix # shell tools
    # ../../user/apps/terminal/lazyvim.nix
    ../../user/apps/terminal/myvim.nix
    ../../user/apps/terminal/helix.nix
    ../../user/apps/terminal/alacritty.nix
    ../../user/apps/terminal/kitty.nix
    ../../user/wm/aerospace
  ];

  home.packages = with pkgs; [
    # cachix
    diff-so-fancy
    git
  ];
  home.stateVersion = "24.05";

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

  home.file.".config/sketchybar" = {
    source = ../../user/config/sketchybar;
    recursive = true;
  };

  # programs.fish.enable = true;
  # programs.zsh.enable = true;

  home.file.".config/wezterm/wezterm.lua".text = ''
    local wezterm = require 'wezterm'
    local config = wezterm.config_builder()

    config.color_scheme = 'AyuDark (Gogh)'
    config.font = wezterm.font 'VictorMono Nerd Font'
    config.freetype_load_flags = 'NO_HINTING'

    config.enable_tab_bar = false
    config.window_decorations = "RESIZE"
    config.window_padding = {
      left = 0,
      right = 0,
      top = 0,
      bottom = 0,
    }

    return config
  '';
}

