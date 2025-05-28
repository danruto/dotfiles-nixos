{ pkgs-unstable, ... }:

let
  unstable-packages = with pkgs-unstable; [
    neovim
  ];
in
{

  home.packages = unstable-packages;

  home.file.".config/nvim" = {
    recursive = true;
    source = ./configs/nvim;
  };
}
