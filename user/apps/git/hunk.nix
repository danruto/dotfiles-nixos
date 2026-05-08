{ lib, stdenv, fetchurl, autoPatchelfHook }:

let
  version = "0.10.0";

  sources = {
    "x86_64-linux" = {
      asset = "hunkdiff-linux-x64";
      sha256 = "sha256-ND3Kb1u0B5O+joNCvE4LzJjYpSFnt5QWDFGmuAmYns8=";
    };
    "aarch64-linux" = {
      asset = "hunkdiff-linux-arm64";
      sha256 = "sha256-epaG0urTx3nqr2mIClkDLzrxf+gOZE4EDyC0YyEPq8M=";
    };
    "x86_64-darwin" = {
      asset = "hunkdiff-darwin-x64";
      sha256 = "sha256-70O4DI3+7ZuZstem8QeiL/qrj9M65nYVflqzqUlpnSY=";
    };
    "aarch64-darwin" = {
      asset = "hunkdiff-darwin-arm64";
      sha256 = "sha256-cdiwcZPevnbhlpsHzPeRVsb5WQdunaNlTCKh+XwarUU=";
    };
  };

  src = sources.${stdenv.hostPlatform.system}
    or (throw "hunk: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "hunk";
  inherit version;

  src = fetchurl {
    url = "https://github.com/modem-dev/hunk/releases/download/v${version}/${src.asset}.tar.gz";
    inherit (src) sha256;
  };

  nativeBuildInputs = lib.optional stdenv.isLinux autoPatchelfHook;

  sourceRoot = src.asset;

  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 hunk $out/bin/hunk
    runHook postInstall
  '';

  meta = {
    description = "Review-first terminal diff viewer for agent-authored changesets";
    homepage = "https://github.com/modem-dev/hunk";
    license = lib.licenses.mit;
    mainProgram = "hunk";
    platforms = builtins.attrNames sources;
  };
}
