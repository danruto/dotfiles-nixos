{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    lmstudio
  ];
}
