# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, blocklist-hosts, username, name, hostname, timezone, locale, wm, theme, nixos-hardware, ... }:

with lib;
{
  imports =
    [
      # lanzaboote.nixosModules.lanzaboote,
      # nixos-hardware.nixosModules.common-hidpi,
      nixos-hardware.nixosModules.framework-12th-gen-intel
      nixos-hardware.nixosModules.common-pc-ssd
      nixos-hardware.nixosModules.common-cpu-intel
      nixos-hardware.nixosModules.common-gpu-intel
      ./hardware-configuration.nix
      ../../system/hardware/bluetooth.nix
      ../../system/hardware/monitor.nix
      ../../system/hardware/opengl.nix
      ../../system/hardware/power.nix
      ../../system/security/gpg.nix
      ../../system/security/blocklist.nix
      ../../system/wm/wayland.nix
      ../../system/wm/hyprland.nix
      ../../system/wm/fonts.nix
      ../../system/apps/starship.nix
    ];

  # Setup bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Fix nix path
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=$HOME/dotfiles/system/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];

  # Experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Ensure nix flakes are enabled
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 7d";
  };

  nixpkgs.config.allowUnfree = true;

  # TODO: Move to modules Networking
  networking.hostName = hostname; # Define your hostname.
  networking.networkmanager.enable = true;

  # Timezone and locale
  time.timeZone = timezone; # time zone
  i18n.defaultLocale = locale;

  # User account
  users.users.${username} = {
    isNormalUser = true;
    description = name;
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [ ];
    uid = 1000;
  };
  security.sudo.wheelNeedsPassword = false;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };

  security.pam.services.login.fprintAuth = true;

  # System packages
  environment.systemPackages = with pkgs; [
    helix
    wget
    fish
    git
    home-manager
    starship
    kitty
  ];

  environment.shells = with pkgs; [ fish ];
  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;

  # TODO: Move to modules
  services.openssh.enable = true;
  services.fwupd.enable = true;

  # It is ok to leave this unchanged for compatibility purposes
  system.stateVersion = "23.11";

}
