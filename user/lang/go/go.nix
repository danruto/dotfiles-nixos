{ pkgs, pkgs-unstable, ... }:

let
  unstable-packages = with pkgs-unstable; [
    go
    gopls
    gofumpt
    golangci-lint
    gotestsum
    delve
  ];
  stable-packages = with pkgs; [
  ];
in
{
  home.packages = stable-packages
    ++ unstable-packages;
}
