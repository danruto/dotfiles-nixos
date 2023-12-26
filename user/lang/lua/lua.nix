{ config, pkgs, ... }:

let
  unstable-packages = with pkgs.unstable; [
  ];
  stable-packages = with pkgs; [
		lua
		sumneko-lua-language-server
		lua52Packages.luacheck
  ];
  in
{
  home.packages = stable-packages
                ++ unstable-packages;
}
