{ lib, stdenvNoCC, fetchurl, buildFHSEnv }:

let
  version = "0.12.0";

  sources = {
    "x86_64-linux" = {
      asset = "gloomberb-linux-x64";
      sha256 = "0pifal57qysbs81zwp082axb3fda6j2agfcv02a1vv6bp55ck9d1";
    };
    "aarch64-linux" = {
      asset = "gloomberb-linux-arm64";
      sha256 = "0b7v9sq309ixyp1w4r0ixfc9b4vz78zvfjjpmj3qzv4rbc1v2rpn";
    };
    "aarch64-darwin" = {
      asset = "gloomberb-darwin-arm64";
      sha256 = "0lk1hbq5yylvnm5lly32716rc0vm8mwfy6z76fvg4cd6mhd2avzw";
    };
  };

  src' = sources.${stdenvNoCC.hostPlatform.system}
    or (throw "gloomberb: unsupported system ${stdenvNoCC.hostPlatform.system}");

  meta = with lib; {
    description = "Finance terminal, in your terminal";
    homepage = "https://github.com/vincelwt/gloomberb";
    license = licenses.mit;
    mainProgram = "gloomberb";
    platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
  };

  # The release binaries are Bun single-file executables: the app payload is
  # appended after the ELF with a magic trailer at EOF. patchelf relocates ELF
  # sections past that trailer, which corrupts it and makes the binary fall back
  # to a plain Bun runtime. So we MUST keep the binary byte-for-byte unmodified.
  raw = stdenvNoCC.mkDerivation {
    pname = "gloomberb-unwrapped";
    inherit version meta;

    src = fetchurl {
      url = "https://github.com/vincelwt/gloomberb/releases/download/v${version}/${src'.asset}.gz";
      inherit (src') sha256;
    };

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      gunzip -c $src > $out/bin/gloomberb
      chmod +x $out/bin/gloomberb
      runHook postInstall
    '';
  };
in
# Darwin's Mach-O binary runs natively (ad-hoc signed); nothing to patch.
# On Linux the binary's ELF interpreter is /lib/ld-linux-*.so.1, absent on
# NixOS. Run it unmodified inside an FHS env so the loader resolves without
# touching the binary and /proc/self/exe stays the real binary (Bun reads it to
# locate its embedded payload).
if stdenvNoCC.hostPlatform.isDarwin then raw
else buildFHSEnv {
  pname = "gloomberb";
  inherit version meta;
  runScript = "${raw}/bin/gloomberb";
}
