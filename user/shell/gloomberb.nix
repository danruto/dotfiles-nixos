{ lib, stdenvNoCC, fetchurl, buildFHSEnv }:

let
  version = "0.8.1";

  sources = {
    "x86_64-linux" = {
      asset = "gloomberb-linux-x64";
      sha256 = "0aqqndj1h2nnkvxfcp3fi18kifhcava4qnrqnnspj32y6krrnqwb";
    };
    "aarch64-linux" = {
      asset = "gloomberb-linux-arm64";
      sha256 = "0jc3cr9v98r6v4bwf7608a4dqrrb3ll7imary4nsm3ldgk0ipa2g";
    };
    "aarch64-darwin" = {
      asset = "gloomberb-darwin-arm64";
      sha256 = "0wl88zc9hxdfknzblliy60qrhw6bhba1m9zcd3y81zz0rclxang1";
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
if stdenvNoCC.isDarwin then raw
else buildFHSEnv {
  pname = "gloomberb";
  inherit version meta;
  runScript = "${raw}/bin/gloomberb";
}
