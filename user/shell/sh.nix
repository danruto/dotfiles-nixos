{ config, pkgs, ... }:
let

  # My shell aliases
  myAliases = {
    ls = "eza --icons -l -T -L=1";
    cat = "bat";
    fd = "fd -Lu";
    zj = "zellij --layout compact";
    # nixos-rebuild = "systemd-run --no-ask-password --uid=0 --system --scope -p MemoryLimit=16000M -p CPUQuota=60% nixos-rebuild";
    # home-manager = "systemd-run --no-ask-password --uid=1000 --user --scope -p MemoryLimit=16000M -p CPUQuota=60% home-manager";
    norb = "sudo nixos-rebuild switch --flake .#system";
    hmr = "home-manager switch -b backup --flake .#user";
    nu = "nix flake update";
    nuh = "nix flake update && hmr";
    nc = "nix-collect-garbage && nix-collect-garbage -d && rm /nix/var/nix/gcroots/auto/* && nix-collect-garbage && nix-collage-garbage -d";
  };
in
{
  programs.fish = {
    enable = true;
    shellAliases = myAliases;
  };

  programs.zsh = {
    enable = false;
    shellAliases = myAliases;
  };

  programs.eza.enable = true;

  home.packages = with pkgs; [
    fd
    direnv
    nix-direnv
    starship
    fish
  ];

  programs.btop = {
    enable = true;
    settings = {
      vim_keys = true;
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      load_dotenv = true;
    };
  };

  programs.starship.enableFishIntegration = true;

  programs.zellij = {
    enable = true;
    enableFishIntegration = false;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
