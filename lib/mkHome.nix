# Builds a standalone homeConfiguration for non-NixOS / non-owned-root targets.
# Imports the same hosts/<host>/home.nix as the system-module path; the only
# difference is the injected platform = "standalone".
{ inputs, lib, pkgsBySystem, defaults, baseSpecialArgs, home-manager }:

{ hostname
, system
, ...
}@hostArgs:
let
  p = pkgsBySystem.${system};

  identity = removeAttrs hostArgs [ "hostname" "system" ];
  id = defaults // identity;
in
home-manager.lib.homeManagerConfiguration {
  pkgs = p.pkgs;
  modules = [ (../hosts + "/${hostname}/home.nix") ];
  extraSpecialArgs = baseSpecialArgs // id // {
    inherit hostname system;
    platform = "standalone";
    inherit (p) pkgs-unstable pkgs-master fontPkg;
  };
}
