{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "iris";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "versenilvis";
    repo = "iris";
    tag = "v${version}";
    hash = "sha256-bfwWkKPdRA3vE04ovn6b2DUyp1nDtDtN/6j0pVk9thA=";
  };

  subPackages = [ "cmd/iris" ];

  proxyVendor = true;
  vendorHash = "sha256-huyTWK6ef42KY2zmFIQuFoeR8B8XKHE7OVfFnfefeCU=";

  doCheck = false;

  meta = with lib; {
    description = "Shell auto-completion tool that works like a code editor's IntelliSense";
    homepage = "https://github.com/versenilvis/iris";
    license = licenses.bsd0;
    mainProgram = "iris";
    platforms = platforms.unix;
  };
}
