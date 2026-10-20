{ lib, stdenv, fetchurl, autoPatchelfHook }:

let
  version = "0.24.0";

  sources = {
    "x86_64-linux" = {
      asset = "hunkdiff-linux-x64";
      sha256 = "sha256-dlZAKo671RF60k4SvaGvBF/JyFw7QOctv95N6nm2DGk=";
    };
    "aarch64-linux" = {
      asset = "hunkdiff-linux-arm64";
      sha256 = "sha256-6qup9cDBhNtKhJOsOGsRLujLtVOITEoOXgQTje9eLSk=";
    };
    "x86_64-darwin" = {
      asset = "hunkdiff-darwin-x64";
      sha256 = "sha256-fmTbYyJ2rPNUWXppZswOKHmgMZDh2/wMOnE1Nfr14JA=";
    };
    "aarch64-darwin" = {
      asset = "hunkdiff-darwin-arm64";
      sha256 = "sha256-+Hbx6G1rqI4SCTfrefY4iXYqKf7ZUSNtbeac4/+WeBk=";
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

  nativeBuildInputs = lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;

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
