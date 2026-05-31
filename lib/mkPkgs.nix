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

  nixpkgs-patched = (import nixpkgs { inherit system; }).applyPatches {
    name = "nixpkgs-patched";
    src = nixpkgs;
    patches = [ ];
  };

  nixpkgs-unstable-patched = (import nixpkgs { inherit system; }).applyPatches {
    name = "nixpkgs-unstable-patched";
    src = nixpkgs-unstable;
    patches = [ ];
  };

  pkgs = import nixpkgs-patched {
    inherit system config;
    overlays = overlays.common;
  };

  pkgs-unstable = import nixpkgs-unstable-patched {
    inherit system config;
    overlays = overlays.unstable;
  };

  pkgs-master = import nixpkgs-master {
    inherit system config;
  };
in
{
  inherit pkgs pkgs-unstable pkgs-master;
  fontPkg = pkgs.d2coding;
}
