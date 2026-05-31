{ ... }: {
  imports = [
    ../user/apps/terminal/ghostty.nix
    ../user/apps/terminal/zellij.nix
    ../system/apps/starship.nix
  ];

  home.sessionVariables = {
    EDITOR = "hx";
  };

  # Disable manuals until sourcehut references are removed from home-manager
  manual.manpages.enable = false;
  manual.json.enable = false;
  manual.html.enable = false;
}

