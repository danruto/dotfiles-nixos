{ pkgs, pkgs-unstable, ... }:

let
  unstable-packages = with pkgs-unstable; [
  ];
  stable-packages = with pkgs; [
    nil
    alejandra
    deadnix
    statix
  ];
in
{
  home.packages = stable-packages
    ++ unstable-packages;
}
