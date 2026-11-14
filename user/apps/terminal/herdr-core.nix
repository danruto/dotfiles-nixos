{ lib, stdenvNoCC, fetchurl }:
let
  version = "0.1.21";
  targets = {
    x86_64-linux = {
      name = "linux-x86_64";
      sha256 = "78424755c10a40dde38a0bdb55c20ac19706e9ae05ed68fc2acf1fcff0d941c1";
    };
    aarch64-linux = {
      name = "linux-aarch64";
      sha256 = "e844a2bfab48a226097679d076bc83042fe57fccef5387ef802e5b24e78b529a";
    };
    x86_64-darwin = {
      name = "macos-x86_64";
      sha256 = "e377e1d342cddce0346da5b2f3c281b9701e4731c00024c7c5028265e77a217f";
    };
    aarch64-darwin = {
      name = "macos-aarch64";
      sha256 = "1ab38dd9270f63a8f794d6d60e8702eb0d1c85a72bda85d735e5eea43f05ffed";
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
