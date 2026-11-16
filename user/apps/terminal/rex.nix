{ config, pkgs, rex, hostname, ... }:

let
  home = config.home.homeDirectory;
in
{
  imports = [ rex.homeModules.default ];

  services.rex.enable = true;
  services.rex.tailscale = {
    enable = true;
    hostname = "rex-${hostname}";
  };

  # Rex's embedded Tailscale (off by default) uploads logs unless this is set.
  services.rex.environment.TS_NO_LOGS_NO_SUPPORT = "true";

  # ~/.ssh/config is hand-managed here, so home-manager can't add the guard.
  programs.rex.sshGuard = false;

  # Same live-linked config as the Mac (rex-app.nix): this server's clients get
  # the herdr keys and actions, and hc-rex-sync runs from the working tree.
  home.file.".config/rex".source =
    config.lib.file.mkOutOfStoreSymlink "${home}/dotfiles-nixos/user/apps/terminal/configs/rex";

  # Mirrors herdr-app's spaces, tabs and splits into Rex and back.
  systemd.user.services.hc-rex-sync = {
    Unit = {
      Description = "Sync herdr-app's layout with Rex";
      After = [ "rex.service" ];
      Wants = [ "rex.service" ];
    };
    Service = {
      ExecStart = "${pkgs.nodejs}/bin/node ${home}/.config/rex/hc-rex-sync.mjs";
      Environment = [ "PATH=${home}/.nix-profile/bin:${home}/.local/bin:/usr/bin:/bin" ];
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Tab status emoji, as launchd runs it on the Mac. `rex do` exits when the
  # server restarts; systemd starts it again.
  systemd.user.services.rex-status = {
    Unit = {
      Description = "Rex tab status emoji";
      After = [ "rex.service" ];
      Wants = [ "rex.service" ];
    };
    Service = {
      ExecStart = "${config.services.rex.package}/bin/rex do --all ${home}/.config/rex/status.lua";
      Restart = "always";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
