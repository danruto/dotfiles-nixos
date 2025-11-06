{ config, lib, pkgs, stdenv, fetchurl, stylix, username, email, theme, wm, editor, vicinae, ... }:

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
    # ../../user/lang/rust/rust.nix # Rust tools
    ../../user/lang/typescript/typescript.nix # typescript tools
    ../../user/lang/go/go.nix # go tools
    ../../user/lang/lua/lua.nix # lua tools
    ../../user/lang/nix/nix.nix # nix tools
    ../../user/lang/shell/shell.nix # shell tools
    # ../../user/apps/terminal/lazyvim.nix
    ../../user/apps/terminal/myvim.nix
    ../../user/apps/terminal/music.nix
    ../../user/apps/terminal/curl.nix # network request cli/tuis
    # ../../user/apps/terminal/helix.nix
    ../../user/apps/terminal/helix-fork.nix
    # ../../user/apps/terminal/alacritty.nix
    ../../user/apps/terminal/kitty.nix
    ../../user/apps/terminal/foot.nix
    # ../../user/wm/hyprland/hyprland.nix
    ../../user/wm/niri/niri.nix
    # ../../user/apps/ai/llm.nix
    # ../../user/apps/ai/lmstudio.nix
    ../../user/apps/browser/brave.nix
    ../../user/apps/browser/ff.nix
    # ../../user/apps/browser/librewolf.nix
    # ../../user/apps/fileman/dolphin.nix
    # ../../user/apps/fileman/thunar.nix
    ../../user/apps/fileman/cosmic.nix
    # ../../user/apps/fileman/nemo.nix
    ../../user/apps/fileman/yazi.nix
    # ../../user/apps/gui/gui.nix
    # ../../user/apps/gui/neovide.nix
    # ../../user/apps/gui/vscode.nix
    # ../../user/apps/gui/zed.nix
    # ../../user/apps/networking/wireguard.nix
    # ../../user/apps/security/1password.nix
    # ../../user/apps/security/protonvpn.nix
    # ../../system/hardware/monitor.nix
    # ../../user/hardware/keyboard.nix
    # ../../user/apps/virt/virt.nix
    # ../../user/style/catppuccin.nix
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
