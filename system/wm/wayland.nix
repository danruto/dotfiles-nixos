{ lib, pkgs, ... }:

{
  imports = [
    ./pipewire.nix
    ./dbus.nix
    ./gnome-keyring.nix
    ./fonts.nix
  ];

  environment.systemPackages = with pkgs; [
    wayland
    xwayland
    meson
    wayland-protocols
    wayland-utils
    wl-clipboard
    wlroots
  ];

  # Configure xwayland
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
      options = "caps:escape";
    };
  };
  # GDM pulled in half of GNOME for a login screen; greetd+tuigreet lists
  # the installed wayland sessions (niri, hyprland) with no desktop env.
  services.displayManager.gdm.enable = false;
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${lib.getExe pkgs.greetd.tuigreet} --time --remember --remember-session --sessions /run/current-system/sw/share/wayland-sessions";
      user = "greeter";
    };
  };

  # Security
  security = {
    pam.services.swaylock = {
      text = ''
        auth include login
      '';
    };
    pam.services.login.enableGnomeKeyring = true;
    pam.services.greetd.enableGnomeKeyring = true;
  };

}
