{ pkgs, pkgs-unstable, ... }:

let
  stable-packages = with pkgs; [
  ];

  unstable-packages = with pkgs-unstable; [
    # zed-editor
    zed-editor-fhs
  ];
in
{
  home.packages = stable-packages ++ unstable-packages;
}
