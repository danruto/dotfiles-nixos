{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "readpanda";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "sonirico";
    repo = "readpanda";
    tag = "v${version}";
    hash = "sha256-ZAk/7n+RdBbs2T1pXOXKyu5ndAxNL71qQUeKpSF176o=";
  };

  vendorHash = "sha256-E9oL05U0BBzvD3q46i35JUNh1OJzA0BINKT81sSSStY=";

  subPackages = [ "cmd/readpanda" ];
  ldflags = [ "-s" "-w" ];

  meta = {
    description = "Terminal UI for Redpanda and Kafka";
    homepage = "https://github.com/sonirico/readpanda";
    license = lib.licenses.mit;
    mainProgram = "readpanda";
  };
}
