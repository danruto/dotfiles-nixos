# Builds a nixosConfiguration or darwinConfiguration for one host, with
# home-manager wired in as a system module (useGlobalPkgs + useUserPackages).
# Dispatches on `platform` ("nixos" | "darwin").
{ inputs, lib, pkgsBySystem, overlays, defaults, baseSpecialArgs, home-manager, darwin }:

{ hostname
, system
, platform ? "nixos"
, extraModules ? [ ]
, ...
}@hostArgs:
let
  p = pkgsBySystem.${system};

  # Per-host identity overrides are any args beyond the structural keys.
  identity = removeAttrs hostArgs [ "hostname" "system" "platform" "extraModules" ];
  id = defaults // identity;

  isDarwin = platform == "darwin";

  specialArgs = baseSpecialArgs // id // {
    inherit hostname system platform;
    inherit (p) pkgs-unstable pkgs-master fontPkg;
  };

  nixpkgsModule = {
    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
      allowBroken = true;
    };
    nixpkgs.overlays = if isDarwin then overlays.darwin else overlays.common;
  };

  hmModule = {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "backup";
    home-manager.users.${id.username} = import (../hosts + "/${hostname}/home.nix");
    home-manager.extraSpecialArgs = specialArgs;
  };

  hmSystemModule =
    if isDarwin
    then home-manager.darwinModules.home-manager
    else home-manager.nixosModules.home-manager;

  modules = [
    (../hosts + "/${hostname}/configuration.nix")
    nixpkgsModule
    hmSystemModule
    hmModule
  ] ++ extraModules;

  builder = if isDarwin then darwin.lib.darwinSystem else lib.nixosSystem;
in
builder {
  inherit system modules specialArgs;
}
