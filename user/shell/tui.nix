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
    vhs
    # asciinema
    # aerc
    # podman-tui
    # dive
    # openapi-tui
    television
    wrkflw
    lfk
    mdfried
  ] ++ lib.optionals pkgs-unstable.stdenv.isLinux [
  ];
in
{
  home.packages = stable-packages
    ++ unstable-packages
    ++ [
    (pkgs.callPackage ./gloomberb.nix { })
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
    ./cull.nix
  ];

  programs.bat.enable = true;
}
