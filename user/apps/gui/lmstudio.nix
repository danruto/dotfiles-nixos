{ pkgs, ... }:
{
  home.packages = with pkgs.unstable; [
    lmstudio
  ];
}
