{ ... }:

{
  # Outbound WireGuard mesh. Nothing dials in, so the host stays reachable from
  # any network, CGNAT included. This is the path mosh rides: Cloudflare Tunnel
  # only carries TCP and mosh's second phase is UDP, so mosh hangs over it.
  # One-off login per host: `sudo tailscale up --hostname=<hostname>`.
  services.tailscale.enable = true;

  # Installs mosh-server into environment.systemPackages, where a
  # non-interactive ssh session finds it. A home-manager package would not:
  # ~/.nix-profile/bin is not on the PATH of a bare `ssh <host> mosh-server`.
  # Also opens UDP 60000-61000, which mosh-server needs.
  programs.mosh.enable = true;
}
