{ pkgs, ... }:

let
  # niT-Tin/oz ships prebuilt release binaries; fetch one instead of building
  # with zig. Bump version + all four hashes together.
  version = "0.2.0";
  sources = {
    "x86_64-linux" = { suffix = "x86_64-linux"; hash = "sha256-4Q0/IlVo5tyuhrG6/CM6jN9Fy2ed6OTtA53Pglk6EWs="; };
    "aarch64-linux" = { suffix = "aarch64-linux"; hash = "sha256-YIhUegKysTw6197KZIgoT5hQC6pXGJJc4nT/rG2RLhg="; };
    "x86_64-darwin" = { suffix = "x86_64-macos"; hash = "sha256-ql6T/U1bCZGwL7ljWSKguI/diiaZmU7uqnlbxIt5YkM="; };
    "aarch64-darwin" = { suffix = "aarch64-macos"; hash = "sha256-NyyAGvaVL4fDRGMx2rwHOiN5oj7dL1G2GsRixI3UXgs="; };
  };
  target = sources.${pkgs.stdenv.hostPlatform.system};

  oz = pkgs.stdenvNoCC.mkDerivation {
    pname = "oz";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/niT-Tin/oz/releases/download/v${version}/oz-${target.suffix}.tar.gz";
      inherit (target) hash;
    };
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      install -Dm755 oz $out/bin/oz
      runHook postInstall
    '';
    meta = {
      description = "Vim-like terminal text editor written in Zig";
      homepage = "https://github.com/niT-Tin/oz";
      license = pkgs.lib.licenses.mit;
      mainProgram = "oz";
      platforms = builtins.attrNames sources;
    };
  };
in
{
  home.packages = [ oz ];
}
