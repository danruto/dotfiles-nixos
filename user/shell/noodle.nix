{ lib, stdenvNoCC, fetchurl, buildFHSEnv }:

let
  version = "0.8.4";

  sources = {
    "x86_64-linux" = {
      asset = "noodle-linux-x86_64";
      hash = "sha256-DsKF5vX/zpF+fmx8wAXi80priYDBz51InS9F/3inDho=";
    };
    "aarch64-linux" = {
      asset = "noodle-linux-arm64";
      hash = "sha256-w+twLfqlb+YmyWekafLiZbifSo86F2dbxxZvFKDd2co=";
    };
    "aarch64-darwin" = {
      asset = "noodle-macos-arm64";
      hash = "sha256-bA8MCdAf7lcWeV7O3Rn7H6TDAAmwi6pQzGX/iodDgYw=";
    };
  };

  src' = sources.${stdenvNoCC.hostPlatform.system}
    or (throw "noodle: unsupported system ${stdenvNoCC.hostPlatform.system}");

  meta = with lib; {
    description = "A delicious REST client for your terminal";
    homepage = "https://github.com/wilfredinni/noodle";
    license = licenses.asl20;
    mainProgram = "noodle";
    platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
  };

  # Same constraint as gloomberb: these are Bun single-file executables with the
  # app payload appended after the ELF and a magic trailer at EOF. patchelf
  # relocates sections past that trailer and corrupts it, so the binary must stay
  # byte-for-byte unmodified.
  raw = stdenvNoCC.mkDerivation {
    pname = "noodle-unwrapped";
    inherit version meta;

    src = fetchurl {
      url = "https://github.com/wilfredinni/noodle/releases/download/v${version}/${src'.asset}";
      inherit (src') hash;
    };

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp $src $out/bin/noodle
      chmod +x $out/bin/noodle
      runHook postInstall
    '';
  };
in
if stdenvNoCC.hostPlatform.isDarwin then raw
else buildFHSEnv {
  pname = "noodle";
  inherit version meta;
  runScript = "${raw}/bin/noodle";
}
