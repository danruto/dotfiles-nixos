{ pkgs, pkgs-unstable, ... }:

let
  stable-packages = with pkgs; [
    # blueman
  ];

  # TODO: mpv, nemo, vscode should be it's own modules as it needs settings
  unstable-packages = with pkgs-unstable; [
    vesktop
    # insomnium
    # insomnia
    mpv
    slack
    obs-studio
  ];
in
{
  home.packages = stable-packages ++ unstable-packages;

}
