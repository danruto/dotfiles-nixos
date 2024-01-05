
{ config, pkgs, ... }:
let

  # My shell aliases
  myAliases = {
    ls = "eza --icons -l -T -L=1";
    cat = "bat";
    fd = "fd -Lu";
    # nixos-rebuild = "systemd-run --no-ask-password --uid=0 --system --scope -p MemoryLimit=16000M -p CPUQuota=60% nixos-rebuild";
    # home-manager = "systemd-run --no-ask-password --uid=1000 --user --scope -p MemoryLimit=16000M -p CPUQuota=60% home-manager";
    norb = "sudo nixos-rebuild switch --flake .#system";
    hmr = "home-manager switch --flake .#user";
    nu = "nix flake update";
    nuh = "nix flake update && hmr";
  };
in
{
  programs.fish = {
    enable = true;
    shellAliases = myAliases;
  };

  home.packages = with pkgs; [
    bat 
    eza 
    gotop
    fd
    direnv 
    nix-direnv
    starship
    fish
  ];

  programs.direnv.enable = true;
  # programs.direnv.enableFishIntegration = true;
  programs.direnv.nix-direnv.enable = true;

  programs.starship.enableFishIntegration = true;

  programs.zellij.enable = true;
  programs.zellij.enableFishIntegration = true;

  programs.zoxide.enable = true;
  programs.zoxide.enableFishIntegration = true;
}
