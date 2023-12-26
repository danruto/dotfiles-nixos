{ config, lib, pkgs, ... }:

{
  # Collection of useful CLI apps
  home.packages = with pkgs; [
    # Command Line
    killall
    libnotify
    bat 
    eza 
    fd 
    gotop
    ripgrep
    rsync
    hwinfo
    unzip
    brightnessctl
    fzf
    pandoc
    pciutils
    neovim
		helix
    gitui
    zellij
    zoxide

    (pkgs.writeShellScriptBin "airplane-mode" ''
      #!/bin/sh
      connectivity="$(nmcli n connectivity)"
      if [ "$connectivity" == "full" ]
      then
          nmcli n off
      else
          nmcli n on
      fi
    '')
  ];

  imports = [
  ];
}
