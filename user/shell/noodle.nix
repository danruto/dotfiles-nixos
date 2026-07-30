{ lib, stdenvNoCC, fetchurl, buildFHSEnv }:

let
  version = "0.5.5";

  sources = {
    "x86_64-linux" = {
      asset = "noodle-linux-x86_64";
      hash = "sha256-gVm2o7wASnetNgEBOFn1wX4rmZzvpRuqot1BBsbjqfY=";
    };
    "aarch64-linux" = {
      asset = "noodle-linux-arm64";
      hash = "sha256-y94943R2hX8LNs3OONTGyHJlHBzERFS9274aXEC7bas=";
    };
    "aarch64-darwin" = {
      asset = "noodle-macos-arm64";
      hash = "sha256-sJT9zfwXJ12UHAXUIWh/C9JVBRUV9diCxavkuiYMaGc=";
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
if stdenvNoCC.isDarwin then raw
else buildFHSEnv {
  pname = "noodle";
  inherit version meta;
  runScript = "${raw}/bin/noodle";
}
