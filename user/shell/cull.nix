{ pkgs, ... }:

let
  # legostin/cull ships prebuilt, statically-linked release binaries, so fetch
  # one instead of compiling from source (buildGoModule). This drops the Go
  # build from every rebuild. Bump version + all four hashes together.
  version = "0.6.1";
  sources = {
    "x86_64-linux" = { suffix = "linux_amd64"; hash = "sha256-123umQDoVmflaWxlYFSlAzauo9xRYLrtSRbHoxQe+0c="; };
    "aarch64-linux" = { suffix = "linux_arm64"; hash = "sha256-r4gPEtyS7qbX7SmiZAlpoZ9SsdCYuVV89g4js5/vp0w="; };
    "x86_64-darwin" = { suffix = "darwin_amd64"; hash = "sha256-U1Usvvm27laLrc2Hsrr4/BGM0ircUz6/75gLQiL+KcQ="; };
    "aarch64-darwin" = { suffix = "darwin_arm64"; hash = "sha256-Ut+HEikCmiSyfOFPSjV3xzQQulGLtOHClc6zvUKqmCM="; };
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
