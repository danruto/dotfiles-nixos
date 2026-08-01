{ pkgs, nix-doom-emacs-unstraightened, ... }: {
  imports = [
    nix-doom-emacs-unstraightened.homeModule
    ../user/apps/terminal/ghostty.nix
    ../user/apps/terminal/zellij.nix
    ../user/apps/terminal/herdr.nix
    ../system/apps/starship.nix
  ];

  home.sessionVariables = {
    EDITOR = "hx";
  };

  programs.doom-emacs = {
    enable = false;
    extraBinPackages = with pkgs; [
      git
      ripgrep
      fd
      rust-analyzer
      gopls
      typescript-language-server
    ];
  };

  # Disable manuals until sourcehut references are removed from home-manager
  manual.manpages.enable = false;
  manual.json.enable = false;
  manual.html.enable = false;
}

