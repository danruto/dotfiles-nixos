{ lib, stdenv, fetchurl, autoPatchelfHook }:

let
  version = "0.25.0";

  sources = {
    "x86_64-linux" = {
      asset = "hunkdiff-linux-x64";
      sha256 = "sha256-/DMBFRqbNUALAiPXMEHOqF+xiXLW3FyXorvcQn+tKv4=";
    };
    "aarch64-linux" = {
      asset = "hunkdiff-linux-arm64";
      sha256 = "sha256-Es9KOK4d8oLe4p//5TkTTdaUPWZyU6EcI7HZ7CSfHYg=";
    };
    "x86_64-darwin" = {
      asset = "hunkdiff-darwin-x64";
      sha256 = "sha256-0X+YESQuU2/Lw+cYDFjzBuJ+9DqtQOLovHMAiLF2yWA=";
    };
    "aarch64-darwin" = {
      asset = "hunkdiff-darwin-arm64";
      sha256 = "sha256-Kld5CbR4JCvHWYK+MLwsXr+aAET8OKrZSxEat+mpkuA=";
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
