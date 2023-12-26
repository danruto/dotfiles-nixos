{ config, pkgs, ... }:

let
  unstable-packages = with pkgs.unstable; [
    rustup
  ];
  stable-packages = with pkgs; [
    cargo-cache
    cargo-expand
  ];
  in
{
  home.packages = stable-packages
                ++ unstable-packages;
}
