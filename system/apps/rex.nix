{ rex, username, ... }:

# Shared server on /run/rex/server.sock; members of the rex group can connect.
# Also installs the rex CLI for every user, the xterm-rex terminfo, and the
# SSH fallback in /etc/ssh/ssh_config. `nix flake update rex` moves channel.
{
  imports = [ rex.nixosModules.default ];

  services.rex.enable = true;

  users.users.${username}.extraGroups = [ "rex" ];
}
