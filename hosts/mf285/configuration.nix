{ lib, pkgs, username, hostname, timezone, locale, nixos-hardware, ghostty, ... }:

with lib;
{
  imports = [
    nixos-hardware.nixosModules.common-pc-ssd
    ../../system/hardware/bluetooth.nix
    ../../system/hardware/opengl.nix
    ../../system/security/gpg.nix
    ../../system/security/blocklist.nix
    ../../system/security/sshd.nix
    ../../system/wm/fonts.nix
    ../../system/apps/starship.nix
    ../../system/wm/wayland.nix
    ../../system/wm/niri.nix
    ../../system/wm/dms.nix
    ../../system/apps/docker.nix
    ../../user/apps/fileman/nautilus.nix
    ../../user/apps/browser/helium.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl."vm.swappiness" = 10;

  security.polkit.enable = true;

  nix.settings.download-buffer-size = 524288000;
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=$HOME/dotfiles/system/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.package = pkgs.nixVersions.stable;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;

  networking.hostName = hostname;
  networking.networkmanager.enable = true;
  time.timeZone = timezone;
  i18n.defaultLocale = locale;

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
    ];
    uid = 1000;
  };
  security.sudo.wheelNeedsPassword = false;

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "-";
      item = "nofile";
      value = "1048576";
    }
  ];
  systemd.settings.Manager.DefaultLimitNOFILE = "1048576:1048576";
  systemd.user.extraConfig = "DefaultLimitNOFILE=1048576:1048576";

  virtualisation.libvirtd.enable = false;
  virtualisation.waydroid.enable = false;
  programs.virt-manager.enable = false;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libxcb
      libxkbcommon
      wayland
      vulkan-loader
      libx11
    ];
  };

  environment.sessionVariables.XKB_CONFIG_ROOT = "/run/current-system/sw/share/X11/xkb";

  services.auto-cpufreq.enable = false;
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  environment.systemPackages = with pkgs; [
    vim
    xkeyboard-config
    wget
    fish
    git
    home-manager
    starship
    powertop
    ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  environment.shells = [ pkgs.fish ];
  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;

  services.flatpak.enable = true;
  services.flatpak.packages = [
    "com.gitbutler.gitbutler"
    "com.obsproject.Studio"
    "dev.zed.Zed"
    "io.mpv.Mpv"
    "org.libreoffice.LibreOffice"
  ];
  services.flatpak.overrides."dev.zed.Zed".Environment.ZED_FLATPAK_NO_ESCAPE = "1";

  services.fwupd.enable = true;
  services.fwupd.extraRemotes = [ "lvfs-testing" ];

  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';

  system.stateVersion = "26.05";
}
