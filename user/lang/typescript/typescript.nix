{ pkgs, ... }:

let
  unstable-packages = with pkgs.unstable; [
    # dprint
  ];
  stable-packages = with pkgs; [
    nodejs
    typescript
    nodePackages.pnpm

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
