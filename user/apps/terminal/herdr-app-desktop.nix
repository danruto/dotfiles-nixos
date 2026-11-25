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
  version = "0.1.15";
  targets = {
    x86_64-linux = {
      name = "linux-x86_64";
      sha256 = "f99e1e04be82c0e10b2f69ee7403ca34386f480d92511df5865af4703e7655dd";
    };
    aarch64-linux = {
      name = "linux-aarch64";
      sha256 = "0e5fd95a056452ec31e32fe6aa5a47a8b1d42020ae8f3a10cda2e0a1001d4124";
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
