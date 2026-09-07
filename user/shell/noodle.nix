{ lib, stdenvNoCC, fetchurl, buildFHSEnv }:

let
  version = "0.8.5";

  sources = {
    "x86_64-linux" = {
      asset = "noodle-linux-x86_64";
      hash = "sha256-Hg4/ONv8MEA/RMTRn7QbQGThrANeTqPH7f2ve3EDezk=";
    };
    "aarch64-linux" = {
      asset = "noodle-linux-arm64";
      hash = "sha256-nL9rYLHUAXJDvtZW/yejWIrpP8q65xVYfdfkAIW+1VY=";
    };
    "aarch64-darwin" = {
      asset = "noodle-macos-arm64";
      hash = "sha256-ucINDOdEJJxfQ/1phtcB01+CYvrB9wxXPyVF55HqWvs=";
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
