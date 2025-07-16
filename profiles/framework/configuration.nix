# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, pkgs, username, hostname, timezone, locale, nixos-hardware, ... }:

with lib;
{
  imports =
    [
      # lanzaboote.nixosModules.lanzaboote,
      # nixos-hardware.nixosModules.common-hidpi,
      nixos-hardware.nixosModules.framework-12th-gen-intel
      nixos-hardware.nixosModules.common-pc-ssd
      # nixos-hardware.nixosModules.common-cpu-intel
      # nixos-hardware.nixosModules.common-gpu-intel
      ./hardware-configuration.nix
      ../../system/hardware/bluetooth.nix
      # ../../system/hardware/monitor.nix
      ../../system/hardware/opengl.nix
      ../../system/hardware/power.nix
      ../../system/security/gpg.nix
      ../../system/security/blocklist.nix
      ../../system/wm/fonts.nix
      ../../system/apps/starship.nix

      ../../system/wm/wayland.nix
      ../../system/wm/hyprland.nix
      ../../system/wm/niri.nix
    ];


  # Setup bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "mem_sleep_default=deep" ];
  boot.extraModulePackages = with pkgs.linuxPackages_latest; [
    v4l2loopback
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';
  boot.kernel.sysctl."vm.swappiness" = 10;


  security.polkit.enable = true;

  nix.settings.download-buffer-size = 524288000;

  # Fix nix path
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=$HOME/dotfiles/system/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];

  # Experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Ensure nix flakes are enabled
  nix.package = pkgs.nixVersions.stable;
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
    description = username;
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" ];
    packages = with pkgs; [ ];
    uid = 1000;
  };
  security.sudo.wheelNeedsPassword = false;

  # virt
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };
  virtualisation.libvirtd.enable = true;
  virtualisation.waydroid.enable = false;
  programs.virt-manager.enable = true;

  services.fprintd.enable = true;
  # security.pam.services.login.fprintAuth = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    fish
    git
    home-manager
    starship
    ghostty
    framework-tool
    fw-ectool
  ];

  environment.shells = with pkgs; [ fish ];
  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;

  # TODO: Move to modules
  services.openssh.enable = true;
  services.fwupd.enable = true;
  services.fwupd.extraRemotes = [ "lvfs-testing" ];
  services.fwupd.uefiCapsuleSettings.DisableCapsuleUpdateOnDisk = true;


  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';

  # It is ok to leave this unchanged for compatibility purposes
  system.stateVersion = "23.11";

}
