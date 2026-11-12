{ lib, stdenvNoCC, fetchurl }:
let
  version = "0.1.20";
  targets = {
    x86_64-linux = {
      name = "linux-x86_64";
      sha256 = "ac6b86890c451a37584620aaa438b71bc0d0bd430a2e7c1d7e095f052c414e74";
    };
    aarch64-linux = {
      name = "linux-aarch64";
      sha256 = "5f3037379d15cc76cfc72d2fd1a4262ea1c5b24df278bf7cfd8adcff7b914862";
    };
    x86_64-darwin = {
      name = "macos-x86_64";
      sha256 = "36c0331c3ffea0ffaada195b89a3c7496f7f3fc5bf35e4605c19c84e5c205a56";
    };
    aarch64-darwin = {
      name = "macos-aarch64";
      sha256 = "e58985d3fef6e909f33d3c5a4426e4898c81564a557d4636591cec9e3a06af26";
    };
  };
  target = targets.${stdenvNoCC.hostPlatform.system}
    or (throw "herdr-core: no prebuilt binary for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "herdr-core";
  inherit version;

  src = fetchurl {
    url = "https://releases.herdr.dev/core/${version}/herdr-core-${target.name}.tar.gz";
    inherit (target) sha256;
  };

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    install -Dm755 herdr-core $out/bin/herdr-core
    ln -s herdr-core $out/bin/hc
  '';

  meta = {
    description = "Terminals for coding agents that stay alive after you leave";
    homepage = "https://github.com/herdrdev/herdr-core";
    license = lib.licenses.asl20;
    platforms = builtins.attrNames targets;
    mainProgram = "hc";
  };
}
