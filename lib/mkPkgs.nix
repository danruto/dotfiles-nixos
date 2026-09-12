# Instantiate the three nixpkgs channels for a single system, once.
# Called via lib.genAttrs in flake.nix so each system is evaluated a single time.
{ inputs, system, overlays }:
let
  inherit (inputs) nixpkgs nixpkgs-unstable nixpkgs-master;

  config = {
    allowUnfree = true;
    allowUnfreePredicate = (_: true);
    allowBroken = true;
  };

  pkgs = import nixpkgs {
    inherit system config;
    overlays = overlays.common;
  };

  pkgs-unstable = import nixpkgs-unstable {
    inherit system config;
    overlays = overlays.common;
  };

  pkgs-master = import nixpkgs-master {
    inherit system config;
  };
in
{
  inherit pkgs pkgs-unstable pkgs-master;
  fontPkg = pkgs.d2coding;
}
