{ pkgs, pkgs-unstable, ... }:

let
  stable-packages = with pkgs; [
    # blueman
  ];

  # TODO: mpv, nemo, vscode should be it's own modules as it needs settings
  unstable-packages = with pkgs-unstable; [
    discord
    # insomnium
    # insomnia
    mpv
    slack
    vscode
    obs-studio
    zed-editor
  ];
in
{
  home.packages = stable-packages ++ unstable-packages;
}
