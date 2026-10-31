{ lib, stdenvNoCC, fetchurl }:
let
  version = "0.1.15";
  targets = {
    x86_64-linux = {
      name = "linux-x86_64";
      sha256 = "efbb1382da3d5053cb20c60c166a62ec34e73d8299977fb1f5abed28ddec8d66";
    };
    aarch64-linux = {
      name = "linux-aarch64";
      sha256 = "e4939faa57cd1597eb2a07ea34b84cc8f861992c943a08f5e685b41d4d0bfa4f";
    };
    x86_64-darwin = {
      name = "macos-x86_64";
      sha256 = "55acac7e0ba75c829028655cd7e7964d138b10a03946fd73628508a2821b1118";
    };
    aarch64-darwin = {
      name = "macos-aarch64";
      sha256 = "47eba8367e0626a1efced8795fcb03d5434b2541c5a84d78c50cc02c8fb49fc8";
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
