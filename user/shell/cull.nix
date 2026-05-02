{ pkgs, cull-src, ... }:

let
  cull = pkgs.buildGoModule {
    pname = "cull";
    version = cull-src.shortRev or "dev";
    src = cull-src;

    vendorHash = "sha256-1qfkALCIV6ikih0QpAxOXVzTFeRK9AxMbI99WYTlYeA=";

    doCheck = false;

    meta = {
      description = "Interactive TUI disk space analyzer";
      homepage = "https://github.com/legostin/cull";
      mainProgram = "cull";
    };
  };
in
{
  home.packages = [ cull ];
}
