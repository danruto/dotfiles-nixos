{ config, rex, hostname, ... }:

let
  afterRex = {
    After = [ "rex.service" ];
    Wants = [ "rex.service" ];
  };
in
{
  imports = [ rex.homeModules.default ./rex-sync.nix ];

  services.rex.enable = true;
  services.rex.tailscale = {
    enable = true;
    hostname = "rex-${hostname}";
  };

  # Rex's embedded Tailscale (off by default) uploads logs unless this is set.
  services.rex.environment.TS_NO_LOGS_NO_SUPPORT = "true";

  # ~/.ssh/config is hand-managed here, so home-manager can't add the guard.
  programs.rex.sshGuard = false;

  local.rexSync.rexBin = "${config.services.rex.package}/bin/rex";
  systemd.user.services.hc-rex-sync.Unit = afterRex;
  systemd.user.services.rex-status.Unit = afterRex;
}
