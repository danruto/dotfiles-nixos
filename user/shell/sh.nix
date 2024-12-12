{ pkgs, ... }:
let

  # My shell aliases
  myAliases = {
    ls = "eza --icons -l -T -L=1";
    cat = "bat";
    fd = "fd -Lu";
    # zj = "zellij --layout compact";
    zj = "zellij";
    zjp = "zellij a personal";
    # nixos-rebuild = "systemd-run --no-ask-password --uid=0 --system --scope -p MemoryLimit=16000M -p CPUQuota=60% nixos-rebuild";
    # home-manager = "systemd-run --no-ask-password --uid=1000 --user --scope -p MemoryLimit=16000M -p CPUQuota=60% home-manager";
    norb = "sudo nixos-rebuild switch --flake .#system";
    hmr = "home-manager switch -b backup --flake .#user";
    ncu = "sudo nix-channel --update";
    ncl = "sudo nix-channel --list";
    nu = "nix flake update";
    nuh = "nix flake update && hmr";
    ncg = "sudo nix-collect-garbage && sudo nix-collect-garbage -d && sudo rm /nix/var/nix/gcroots/auto/* && sudo nix-collect-garbage && sudo nix-collect-garbage -d";

    # Alias for copying over flakes for new projects
    newgo = "cp ~/dev/pixelbrush/pb-flakes/.envrc . && cp ~/dev/pixelbrush/pb-flakes/.gitignore.default .gitignore && cp ~/dev/pixelbrush/pb-flakes/go.nix flake.nix";
    newrs = "cp ~/dev/pixelbrush/pb-flakes/.envrc . && cp ~/dev/pixelbrush/pb-flakes/.gitignore.default .gitignore && cp ~/dev/pixelbrush/pb-flakes/rust.nix flake.nix";
    newrsn = "cp ~/dev/pixelbrush/pb-flakes/.envrc . && cp ~/dev/pixelbrush/pb-flakes/.gitignore.default .gitignore && cp ~/dev/pixelbrush/pb-flakes/rust-nightly.nix flake.nix";
    newts = "cp ~/dev/pixelbrush/pb-flakes/.envrc . && cp ~/dev/pixelbrush/pb-flakes/.gitignore.default .gitignore && cp ~/dev/pixelbrush/pb-flakes/ts.nix flake.nix";
    newpy = "cp ~/dev/pixelbrush/pb-flakes/.envrc . && cp ~/dev/pixelbrush/pb-flakes/.gitignore.default .gitignore && cp ~/dev/pixelbrush/pb-flakes/python.nix flake.nix";
    newzig = "cp ~/dev/pixelbrush/pb-flakes/.envrc . && cp ~/dev/pixelbrush/pb-flakes/.gitignore.default .gitignore && cp ~/dev/pixelbrush/pb-flakes/zig.nix flake.nix";
  };
in
{
  programs.fish = {
    enable = true;
    shellAliases = myAliases;
    interactiveShellInit = "set fish_greeting";
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
    package = pkgs.unstable.zellij;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
