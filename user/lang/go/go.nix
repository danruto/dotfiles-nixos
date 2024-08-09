{ config, pkgs, ... }:

let
  unstable-packages = with pkgs.unstable; [
  ];
  stable-packages = with pkgs; [
    go
    gopls
    gofumpt
    golangci-lint
  ];
in
{
  home.packages = stable-packages
    ++ unstable-packages;
}
