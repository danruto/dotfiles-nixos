{ helium, ... }:

{
  environment.systemPackages = [
    helium.packages.${system}.default
  ];
}
