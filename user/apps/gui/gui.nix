{ pkgs, pkgs-unstable, ... }:

let
  stable-packages = with pkgs; [
    # blueman
    vesktop
  ];

  # TODO: mpv, nemo, vscode should be it's own modules as it needs settings
  unstable-packages = with pkgs-unstable; [
    # insomnium
    # insomnia
    # mpv - using flatpak instead
    slack
  ];
in
{
  home.packages = stable-packages ++ unstable-packages;

}
