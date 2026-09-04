{ pkgs, ... }:

let
  # legostin/cull ships prebuilt, statically-linked release binaries, so fetch
  # one instead of compiling from source (buildGoModule). This drops the Go
  # build from every rebuild. Bump version + all four hashes together.
  version = "0.9.0";
  sources = {
    "x86_64-linux" = { suffix = "linux_amd64"; hash = "sha256-DC5VW03nX8xUdVmxL7+ysE3vFgsbH5+u/B6Mt/Qcd2k="; };
    "aarch64-linux" = { suffix = "linux_arm64"; hash = "sha256-00zGv5whpM8AWwDK/3/Cdag7Tgk5CifIR98wnI2Bbgg="; };
    "x86_64-darwin" = { suffix = "darwin_amd64"; hash = "sha256-z0vYfXLb2/LCWQNZN0XZ9Eh7mhXTizOqA75Cg14JJK8="; };
    "aarch64-darwin" = { suffix = "darwin_arm64"; hash = "sha256-mbz55XxmJx7tH+mxJEzrQKMgzGzO22wbNLy61I+4lyc="; };
  };
  target = sources.${pkgs.stdenv.hostPlatform.system};

  cull = pkgs.stdenvNoCC.mkDerivation {
    pname = "cull";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/legostin/cull/releases/download/v${version}/cull_${target.suffix}.tar.gz";
      inherit (target) hash;
    };
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      install -Dm755 cull $out/bin/cull
      runHook postInstall
    '';
    meta = {
      description = "Interactive TUI disk space analyzer";
      homepage = "https://github.com/legostin/cull";
      mainProgram = "cull";
      platforms = builtins.attrNames sources;
    };
  };
in
{
  home.packages = [ cull ];
}
