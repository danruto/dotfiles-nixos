{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "obsidian-tui";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "iamrohithrnair";
    repo = "obsidian-tui";
    tag = "v${version}";
    hash = "sha256-IM8gdx3wUENxbBDhY/PsdSt9jiaa3BcSpjDgDsMTrzg=";
  };

  cargoHash = "sha256-7/C8zpoHXW5k6sVQTcKQui+nXnpYCbICL+glOa0F27s=";

  meta = with lib; {
    description = "Obsidian-like terminal UI for your vault: notes, live-preview markdown, backlinks and a force-directed graph";
    homepage = "https://github.com/iamrohithrnair/obsidian-tui";
    license = licenses.gpl3Plus;
    mainProgram = "obsidian-tui";
    platforms = platforms.unix;
  };
}
