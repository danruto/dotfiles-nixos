{ lib, pkgs, pkgs-unstable, ... }:

let
  stable-packages = with pkgs; [
    killall
    libnotify
    rsync
    unzip
    fzf
    pandoc
    pciutils
    tealdeer
    just
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    brightnessctl
    hwinfo
    yt-dlp
    ani-cli
  ];
  unstable-packages = with pkgs-unstable; [
    ripgrep
    asciinema
    # aerc
    # podman-tui
    # dive
    # openapi-tui
    television
  ] ++ lib.optionals pkgs-unstable.stdenv.isLinux [
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
