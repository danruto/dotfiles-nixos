{ lib, rustPlatform, fetchFromGitHub, pkg-config, libxcb, stdenv }:

rustPlatform.buildRustPackage rec {
  pname = "kimun";
  version = "0.21.0";

  src = fetchFromGitHub {
    owner = "nico2sh";
    repo = "kimun";
    tag = "kimun-notes-v${version}";
    hash = "sha256-P0O8NXlpOX4IcDbLDbVs1v0RBPXY5IEN8ItdCweLy04=";
  };

  cargoHash = "sha256-YfiBQe0fYNAq3M3bjpRuuFYH8RjA0+tkFu/8HL6d0zM=";

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
