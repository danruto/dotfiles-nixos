{ helium, pkgs, ... }:

{
  environment.systemPackages = [
    helium.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
