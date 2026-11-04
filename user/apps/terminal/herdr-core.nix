{ lib, stdenvNoCC, fetchurl }:
let
  version = "0.1.18";
  targets = {
    x86_64-linux = {
      name = "linux-x86_64";
      sha256 = "5b2f97cb4b2a9d7a6b2cc5942628203ed9fbb7cc0c2b4b09ad8a6f5648e246b7";
    };
    aarch64-linux = {
      name = "linux-aarch64";
      sha256 = "cf33393cf950bb763734dc3e16610ab9daf8492391a4ef0de56026cd7f752853";
    };
    x86_64-darwin = {
      name = "macos-x86_64";
      sha256 = "15a12b80e93ec4e074dbdb82fa8a66e529857abfbdfb456f94d5116dc438fedc";
    };
    aarch64-darwin = {
      name = "macos-aarch64";
      sha256 = "77d8af092e25ae650f4424d6dad27514f6916a11d807fb0752858cd27c21e4fc";
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
