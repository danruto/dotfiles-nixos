# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, pkgs, ... }:

with lib;
{
  services.nix-daemon.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    wget
    fish
    git
    home-manager
    starship
  ];

  environment.shells = with pkgs; [ fish ];
  programs.fish.enable = true;

  # It is ok to leave this unchanged for compatibility purposes
  system.stateVersion = "23.11";
}
