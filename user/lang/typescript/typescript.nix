{ config, pkgs, ... }:

let
  unstable-packages = with pkgs.unstable; [
  ];
  stable-packages = with pkgs; [
		nodejs
		typescript
		nodePackages.typescript-language-server
		nodePackages.vscode-langservers-extracted
		nodePackages.yaml-language-server
		nodePackages.prettier
		nodePackages.pnpm
  ];
  in
{
  home.packages = stable-packages
                ++ unstable-packages;
}
