{ config, lib, pkgs, ... }:

let
  stable-packages = with pkgs; [
    killall
    libnotify
    rsync
    unzip
    fzf
    pandoc
    pciutils
    tree-sitter
    xh
    tealdeer
    just
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    brightnessctl
    hwinfo
  ];
  unstable-packages = with pkgs.unstable; [
    ripgrep
    yt-dlp
    asciinema
    aerc
  ] ++ lib.optionals pkgs.unstable.stdenv.isLinux [
    ani-cli
  ];
in
{
  home.packages = stable-packages
    ++ unstable-packages
    ++ [
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

  programs.bat.enable = true;
}
