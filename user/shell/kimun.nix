{ lib, rustPlatform, fetchFromGitHub, pkg-config, libxcb, stdenv }:

rustPlatform.buildRustPackage rec {
  pname = "kimun";
  version = "0.23.3";

  src = fetchFromGitHub {
    owner = "nico2sh";
    repo = "kimun";
    tag = "kimun-notes-v${version}";
    hash = "sha256-PpG5bsLDuEFpJrxXtjoNPqg7hT5TAlzT9pDLzbCBg8g=";
  };

  cargoHash = "sha256-D29TnuD9fUw9J5sPnzQI104Unw6PAZ1OXFJT7kWIsTs=";

  # The repo is a workspace (core/tui/client/server); only build the TUI.
  cargoBuildFlags = [ "-p" "kimun-notes" ];

  nativeBuildInputs = [ pkg-config ];

  # arboard talks to the X11 clipboard through libxcb on Linux.
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ libxcb ];

  doCheck = false;

  meta = with lib; {
    description = "Simple note taking, powerful search, AI ready";
    homepage = "https://github.com/nico2sh/kimun";
    license = licenses.mit;
    mainProgram = "kimun";
    platforms = platforms.unix;
  };
}
