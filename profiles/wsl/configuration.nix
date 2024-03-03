# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, nixos-wsl, lib, pkgs, blocklist-hosts, username, name, hostname, timezone, locale, wm, theme, ... }:

with lib;
{
  imports =
    [
      nixos-wsl.nixosModules.wsl
      ../../system/security/gpg.nix
      ../../system/security/blocklist.nix
    ];

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = false;
    wslConf.network.generateHosts = false;
    defaultUser = username;
    startMenuLaunchers = true;

    # Enable native Docker support
    # docker-native.enable = true;

    # Enable integration with Docker Desktop (needs to be installed)
    # docker-desktop.enable = true;
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

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
  # TODO: Probably make new file to cover nix settings
  nix.extraOptions = ''
    experimental-features = nix-command flakes
    keep-outputs = true
    keep-derivations = true
  '';

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 7d";
  };

  # I'm sorry Stallman-taichou
  nixpkgs.config.allowUnfree = true;

  # Networking
  networking.hostName = hostname; # Define your hostname.

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

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    fish
    git
    home-manager
    starship
    # openssl
    # pkg-config

    (import ./win32yank.nix { inherit pkgs; })
  ];

  environment.shells = with pkgs; [ fish ];
  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;
  programs.starship.enable = true;
  programs.starship.settings = {
    gcloud.disabled = true;
    kubernetes.disabled = false;
    git_branch.style = "242";
    directory.style = "bold blue dimmed";
    directory.truncate_to_repo = false;
    directory.truncation_length = 8;
    python.disabled = true;
    ruby.disabled = true;
    hostname.ssh_only = false;
    hostname.style = "bold green";
    memory_usage.disabled = false;
    memory_usage.threshold = -1;
  };

  # It is ok to leave this unchanged for compatibility purposes
  system.stateVersion = "22.05";

}
