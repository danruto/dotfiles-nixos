{ rex, username, ... }:

# The login server runs as root, names tailnet callers through the host's
# tailscaled, and runs one Rex server per account as that account, so remote
# sessions get the account's own login shell. Tailscale Serve publishes it at
# https://<hostname>.<tailnet>.ts.net:7297, which the Rex CLI finds from the
# hostname alone. `nix flake update rex` moves channel.
{
  imports = [ rex.nixosModules.default ];

  services.rex.loginServer = {
    enable = true;
    tailscaleServe.enable = true;
    accounts.${username}.principals = [
      "tailscale:danruto@github"
      "peer:1000"
    ];
    defaults."tailscale:danruto@github" = username;
  };
}
