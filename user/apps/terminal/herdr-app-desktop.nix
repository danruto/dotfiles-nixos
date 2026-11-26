{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, libxcb
, libxkbcommon
, vulkan-loader
, libGL
, wayland
, fontconfig
, freetype
}:
let
  version = "0.1.18";
  targets = {
    x86_64-linux = {
      name = "linux-x86_64";
      sha256 = "8a11edd79dd40b349f7286cf51910b62e21136daf8f03005a9fd2c4dc5830f83";
    };
    aarch64-linux = {
      name = "linux-aarch64";
      sha256 = "3bf51505cb1e7d61e63ccdc2655e8819f4b452babead9922fe4bb6fe69e91350";
    };
  };
  target = targets.${stdenv.hostPlatform.system}
    or (throw "herdr-app: no prebuilt binary for ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "herdr-app";
  inherit version;

  src = fetchurl {
    url = "https://releases.herdr.dev/app/${version}/herdr-app-${target.name}.tar.gz";
    inherit (target) sha256;
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    stdenv.cc.cc.lib
    libxcb
    libxkbcommon
  ];
  # Linked at build time; the rest are dlopen'd at runtime (wgpu, Wayland, fonts).
  runtimeDependencies = [
    vulkan-loader
    libGL
    wayland
    fontconfig
    freetype
  ];

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    install -Dm755 herdr-app/herdr-app $out/bin/herdr-app
    install -Dm644 herdr-app/herdr-app.svg \
      $out/share/icons/hicolor/scalable/apps/herdr-app.svg
    install -Dm644 herdr-app/LICENSE $out/share/licenses/herdr-app/LICENSE
    install -Dm644 herdr-app/THIRD-PARTY-NOTICES \
      $out/share/licenses/herdr-app/THIRD-PARTY-NOTICES
  '';

  meta = {
    description = "Native workspace for coding agents, built on herdr-core";
    homepage = "https://github.com/herdrdev/herdr-app";
    license = lib.licenses.asl20;
    platforms = builtins.attrNames targets;
    mainProgram = "herdr-app";
  };
}
