{ pkgs, herdr, ... }:
{
  home.packages = [ herdr.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  home.file.".config/herdr/config.toml".source = ./configs/herdr/config.toml;
}
