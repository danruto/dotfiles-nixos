{ config, pkgs, ... }:

{
  stable-packages = with pkgs; [
      blueman
  ];

  # TODO: mpv, nemo, vscode should be it's own modules as it needs settings
  unstable-packages = with pkgs.unstable; [
    discord
    firefox
    insomnia
    mpv
    cinnamon.nemo-with-extensions
    slack
    vscode
  ];

  home.packages = stable-packages
                ++ unstable-packages
}
