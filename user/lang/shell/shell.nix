{ config, pkgs, ... }:

let
  unstable-packages = with pkgs.unstable; [
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
