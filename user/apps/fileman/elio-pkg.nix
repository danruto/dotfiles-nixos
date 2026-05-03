{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, oniguruma
, stdenv
, darwin
}:

rustPlatform.buildRustPackage rec {
  pname = "elio";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "elio-fm";
    repo = "elio";
    rev = "v${version}";
    hash = "sha256-CKHpix0rhpvCIjR3sQmOz9klDyC5usDH/egju/D3k9A=";
  };

  cargoLock = {
    lockFile = src + "/Cargo.lock";
  };

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    oniguruma
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.AppKit
  ];

  env = {
    RUSTONIG_SYSTEM_LIBONIG = "1";
  };

  doCheck = false;

  meta = {
    description = "Snappy, batteries-included terminal file manager with rich previews, inline images, bulk actions, and trash support";
    homepage = "https://github.com/elio-fm/elio";
    license = lib.licenses.mit;
    mainProgram = "elio";
  };
}
