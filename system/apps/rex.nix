{ rex, username, ... }:

# Shared server on /run/rex/server.sock; members of the rex group can connect.
# Also installs the rex CLI for every user, the xterm-rex terminfo, and the
# SSH fallback in /etc/ssh/ssh_config. `nix flake update rex` moves channel.
{
  imports = [ rex.nixosModules.default ];

  services.rex.enable = true;

  # Rex sends no telemetry itself; its embedded Tailscale (off by default)
  # would upload logs and metrics to Tailscale unless this is set.
  systemd.services.rex.environment.TS_NO_LOGS_NO_SUPPORT = "true";

  users.users.${username}.extraGroups = [ "rex" ];
}
