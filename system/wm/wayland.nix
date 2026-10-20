{ config, lib, pkgs, ... }:

let
  # Logo is left-aligned inside a box whose inner width (width - 2*padding)
  # equals the logo's 64 columns, so the whole block sits centred.
  tuigreetConfig = (pkgs.formats.toml { }).generate "tuigreet.toml" {
    session.sessions_dirs = [ "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions" ];
    remember = {
      username = true;
      session = true;
    };
    display = {
      greeting = builtins.readFile ./configs/tuigreet-logo.txt;
      align_greeting = "left";
      show_title = false;
      show_time = true;
      time_format = "%H:%M  ·  %a %d %b";
    };
    layout = {
      width = 70;
      container_padding = 3;
      prompt_padding = 1;
    };
    secret = {
      mode = "characters";
      characters = "•";
    };
    theme = {
      container = "black";
      border = "black";
      greet = "white";
      text = "white";
      time = "darkgray";
      prompt = "blue";
      input = "white";
      action = "darkgray";
      button = "blue";
    };
  };
in
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
      command = "${lib.getExe pkgs.tuigreet} --config ${tuigreetConfig}";
      user = "greeter";
    };
  };

  # Minimal login: borderless box on the console background, big
  # wordmark, username remembered so only the password prompt shows.
  # Named ANSI colours, not hex: the VT can't do truecolor, and the console
  # target below maps these names onto the stylix palette.
  stylix.targets.console.enable = true;

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
