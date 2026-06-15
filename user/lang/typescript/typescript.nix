{ pkgs, pkgs-unstable, ... }:

let
  unstable-packages = with pkgs-unstable; [
    # pnpm
    bun
    # dprint
    yarn
  ];
  stable-packages = with pkgs; [
    nodejs
    typescript

    # TODO: These should be from local flakes
    typescript-language-server
    vscode-langservers-extracted
    # yaml-language-server
    # prettier
    tailwindcss-language-server
    # prettierd
  ];
in
{
  home.packages = stable-packages
    ++ unstable-packages;
}
