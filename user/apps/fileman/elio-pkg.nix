{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, oniguruma
, zstd
, sqlite
, stdenv
, darwin
}:

rustPlatform.buildRustPackage rec {
  pname = "elio";
  version = "1.12.0";

  src = fetchFromGitHub {
    owner = "elio-fm";
    repo = "elio";
    rev = "v${version}";
    hash = "sha256-FT5F3L8IgbX6vPjEd+TSudoyIZe4TX7no0FF9C75aaU=";
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
    zstd
    sqlite
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.AppKit
  ];

  env = {
    RUSTONIG_SYSTEM_LIBONIG = "1";
    ZSTD_SYS_USE_PKG_CONFIG = "1";
  };

  doCheck = false;

  meta = {
    description = "Snappy, batteries-included terminal file manager with rich previews, inline images, bulk actions, and trash support";
    homepage = "https://github.com/elio-fm/elio";
    license = lib.licenses.mit;
    mainProgram = "elio";
  };
}
