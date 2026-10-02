{ lib, stdenv, fetchurl, autoPatchelfHook }:

let
  version = "0.23.0";

  sources = {
    "x86_64-linux" = {
      asset = "hunkdiff-linux-x64";
      sha256 = "sha256-eatkBsuyuADnPG+8JUavuX7U+8O1Cq0HLrmtEhUVgeY=";
    };
    "aarch64-linux" = {
      asset = "hunkdiff-linux-arm64";
      sha256 = "sha256-W4korh6YeysXddH+Yu66vMCLn8mUAVTgzvJ9JJQct+Q=";
    };
    "x86_64-darwin" = {
      asset = "hunkdiff-darwin-x64";
      sha256 = "sha256-FMUwJct7s6/WJztlgXq3oQArH46Usk46BU6VJk4WgOA=";
    };
    "aarch64-darwin" = {
      asset = "hunkdiff-darwin-arm64";
      sha256 = "sha256-rkLP5SeYpPUdJfY864aFyipsswOaEk1qb8FyoRL41rg=";
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
