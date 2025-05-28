{ pkgs, pkgs-unstable, ... }:
let
  stable-packages = with pkgs; [
    xh
  ];
  unstable-packages = with pkgs-unstable; [
    posting
    jnv
  ];
in
{
  home.packages = stable-packages ++ unstable-packages;
}
