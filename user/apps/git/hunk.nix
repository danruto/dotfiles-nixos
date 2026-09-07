{ lib, stdenv, fetchurl, autoPatchelfHook }:

let
  version = "0.21.1";

  sources = {
    "x86_64-linux" = {
      asset = "hunkdiff-linux-x64";
      sha256 = "sha256-x9HiO6T/tsozMHl+nwyC262lDjz+G3GfQZR0fyy8oSI=";
    };
    "aarch64-linux" = {
      asset = "hunkdiff-linux-arm64";
      sha256 = "sha256-HTHfw4K5pN+cBF6yOewkj2HEFh3TLsfKqrhZPVWp7KY=";
    };
    "x86_64-darwin" = {
      asset = "hunkdiff-darwin-x64";
      sha256 = "sha256-kMLcftiHkIu1WG3J7JBqDhWw5TpDxZWWjoaGO2KtSWw=";
    };
    "aarch64-darwin" = {
      asset = "hunkdiff-darwin-arm64";
      sha256 = "sha256-x42IH/PmgljKa+faINeG7cBZk6U1zFu6LkopjdwYAbo=";
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
