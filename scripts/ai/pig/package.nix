{ root, package, modulesOnly ? false }:
let
  inputs = (builtins.getFlake root).inputs;
  pkgs = inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
  unstable = inputs.nixpkgs-unstable.legacyPackages.${builtins.currentSystem};
  pig = pkgs.callPackage (builtins.toPath package) {
    buildGoModule = unstable.buildGo127Module;
    go = unstable.go_1_27;
  };
in
if modulesOnly then pig.goModules else pig
