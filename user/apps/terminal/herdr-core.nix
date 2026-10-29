{ lib, stdenvNoCC, fetchurl }:
let
  version = "0.1.14";
  targets = {
    x86_64-linux = {
      name = "linux-x86_64";
      sha256 = "e9dbabdead0ce0ce3de51b6f54cc9549efedbb41b2f8448b6932ab0d1442343e";
    };
    aarch64-linux = {
      name = "linux-aarch64";
      sha256 = "19cef6a2e52f14c22c4b6f3fdaf1a462d2dafc78e8b03fabbfad5b063477a370";
    };
    x86_64-darwin = {
      name = "macos-x86_64";
      sha256 = "8e16ec43a17656f80e7d7f98292bf710c60c4aeff52941cca98fb24f37f35028";
    };
    aarch64-darwin = {
      name = "macos-aarch64";
      sha256 = "ca524329d2e0630219550055dcc71f42aafd85fba356e0d543d6f51244487970";
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
