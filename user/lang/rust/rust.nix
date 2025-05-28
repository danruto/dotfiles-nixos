{ pkgs, pkgs-unstable, ... }:

let
  unstable-packages = with pkgs-unstable; [
    rustup
  ];
  stable-packages = with pkgs; [
    cargo-cache
    cargo-expand
    lldb
  ];
in
{
  home.packages = stable-packages
    ++ unstable-packages;
}
