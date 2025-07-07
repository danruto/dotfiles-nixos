{ pkgs, pkgs-unstable, ... }:

let
  stable-packages = with pkgs; [
  ];

  unstable-packages = with pkgs-unstable; [
    neovide
  ];
in
{
  home.packages = stable-packages ++ unstable-packages;

  home.file.".config/neovide/config.toml".text = ''
    frame = "none"
    theme = "auto"
    title-hidden = true
    vsync = true
    wsl = false

    [font]
    normal = ["D2CodingLigature Nerd Font"] # Will use the bundled Fira Code Nerd Font by default
    size = 14.0
  '';
}
