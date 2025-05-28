{ pkgs, pkgs-unstable, ... }:

let
  unstable-packages = with pkgs-unstable; [
    pnpm
    # dprint
  ];
  stable-packages = with pkgs; [
    nodejs
    typescript

    # TODO: These should be from local flakes
    # nodePackages.typescript-language-server
    # nodePackages.vscode-langservers-extracted
    # nodePackages.yaml-language-server
    # nodePackages.prettier
    # tailwindcss-language-server
    # prettierd
  ];
in
{
  home.packages = stable-packages
    ++ unstable-packages;
}
