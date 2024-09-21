{ pkgs, ... }:

let
  unstable-packages = with pkgs.unstable; [
    zig
    zls
  ];
  stable-packages = with pkgs; [
  ];
in
{
  home.packages = stable-packages
    ++ unstable-packages;
}
