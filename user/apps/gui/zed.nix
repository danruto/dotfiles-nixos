{ pkgs, pkgs-unstable, ... }:

let
  stable-packages = with pkgs; [
  ];

  unstable-packages = with pkgs-unstable; [
    zed-editor
  ];
in
{
  home.packages = stable-packages ++ unstable-packages;
}
