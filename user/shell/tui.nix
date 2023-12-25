{ config, lib, pkgs, ... }:

{
  # Collection of useful CLI apps
  home.packages = with pkgs; [
    # Command Line
    killall
    libnotify
    bat eza fd bottom ripgrep
    rsync
    htop
    hwinfo
    unzip
    brightnessctl
    fzf
    pandoc
    pciutils
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
    neovim
		helix
  ];

  imports = [
  ];
}
