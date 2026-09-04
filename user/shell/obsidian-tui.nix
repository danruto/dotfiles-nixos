{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "obsidian-tui";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "iamrohithrnair";
    repo = "obsidian-tui";
    tag = "v${version}";
    hash = "sha256-GMiXFGRYGIjLD+X0XDBazenPNAmhi2eaqVb4RyG5ebo=";
  };

  cargoHash = "sha256-Y2q0GEXC6D/dPGjJ3qL3Wymsbsljo2aZO9Qe5xPL3Mw=";

  meta = with lib; {
    description = "Obsidian-like terminal UI for your vault: notes, live-preview markdown, backlinks and a force-directed graph";
    homepage = "https://github.com/iamrohithrnair/obsidian-tui";
    license = licenses.gpl3Plus;
    mainProgram = "obsidian-tui";
    platforms = platforms.unix;
  };
}
