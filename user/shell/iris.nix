{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "iris";
  version = "0.4.8";

  src = fetchFromGitHub {
    owner = "versenilvis";
    repo = "iris";
    tag = "v${version}";
    hash = "sha256-JD0mjsQXoMdGLzrSTOyd108D4tiAcVfTJAXIwJCDAR0=";
  };

  subPackages = [ "cmd/iris" ];

  proxyVendor = true;
  vendorHash = "sha256-kBSMhUsuCKIjAXjGfl1WSjCX+tlGi9BTnkRu9ScW6M0=";

  doCheck = false;

  meta = with lib; {
    description = "Shell auto-completion tool that works like a code editor's IntelliSense";
    homepage = "https://github.com/versenilvis/iris";
    license = licenses.bsd0;
    mainProgram = "iris";
    platforms = platforms.unix;
  };
}
