{ lib, stdenvNoCC, fetchurl }:
let
  version = "0.1.17";
  targets = {
    x86_64-linux = {
      name = "linux-x86_64";
      sha256 = "82ec44043f6894bfdb716b979b87cda43fd7fa46b0104e7b7bd93e64d1a9b877";
    };
    aarch64-linux = {
      name = "linux-aarch64";
      sha256 = "3a37a454ec63494cf4306db26481fe9db96673d888723701d24f8a992ae8ab8c";
    };
    x86_64-darwin = {
      name = "macos-x86_64";
      sha256 = "e2dc3211edb1f1c77d0e73dd76c1426636d71050f34a5303916a56d363d7062b";
    };
    aarch64-darwin = {
      name = "macos-aarch64";
      sha256 = "cedbd4d4d9ba1385588198dd4d3c67d2654478f33add5b6445d4d0eb9da5fcf3";
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
