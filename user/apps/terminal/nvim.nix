{ config, unstable-pkgs }:
{
	home.unstable-packages = with unstable-pkgs; [
		neovim
	];
}
