{ pkgs, pkgs-unstable, ... }:

let
  unstable-packages = with pkgs-unstable; [
    awscli2
  ];
  stable-packages = with pkgs; [
    shellcheck
    shfmt
  ];
in
{
  home.packages = stable-packages
    ++ unstable-packages;
}
