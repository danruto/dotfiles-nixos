{ helium, ... }:

{
  environment.systemPackages = [
    helium.packages.x86_64-linux.default
  ];
}
