{ lib, pkgs, pkgs-unstable, username, ... }:

{
  home.packages = [ pkgs-unstable.cloudflared ];

  # Serving this host over ssh needs a persistent outbound connection to the
  # Cloudflare edge — nothing dials in, so a daemon must hold it open. With no
  # arguments `tunnel run` reads ~/.cloudflared/config.yml, so the tunnel id,
  # credentials, and ingress stay per-host outside nix. One-time setup per host:
  #   cloudflared tunnel login
  #   cloudflared tunnel create <host>
  #   cloudflared tunnel route dns <host> ssh-<host>.pixelbru.sh
  # then point config.yml's ingress at ssh://localhost:22. Hosts that skip this
  # have no config.yml and the service stays dormant.
  systemd.user.services.cloudflared-tunnel = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit = {
      Description = "cloudflared tunnel";
      ConditionPathExists = "%h/.cloudflared/config.yml";
    };
    Service = {
      ExecStart = "${pkgs-unstable.cloudflared}/bin/cloudflared tunnel run";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Every exe.dev host — the management surface and every VM behind it — answers
  # with one shared certificate, signed by the account CA and issued to the
  # principals `exe.dev` and `*.exe.dev`. Trusting that CA therefore trusts every
  # VM the account will ever create, which is what makes a VM created by tooling
  # reachable at all: neither just nor an agent shell gives ssh a tty to prompt
  # an unknown host on, so without this a fresh VM simply fails.
  #
  # Kept in a file of its own so ~/.ssh/known_hosts stays mutable and stays first
  # in the search order, and ssh still records ordinary hosts where it always did.
  home.file.".ssh/known_hosts_exedev".text = ''
    @cert-authority exe.dev,*.exe.dev ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJHazMa+PYpGwkvKHQfIav6yR69kKrzyqiii/YGdeCs
  '';

  # home-manager owns ~/.ssh/config when programs.ssh.enable = true,
  # so any "global" defaults must live here as a Host * matchBlock.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # cloudflared tunnel route dns <name> <ssh-name>.pixelbru.sh
    settings = {
      "*.pixelbru.sh" = {
        ProxyCommand = "${pkgs-unstable.cloudflared}/bin/cloudflared access ssh --hostname %h";
        User = username;
        IdentitiesOnly = "yes";
      };

      # VMs are reached at <name>.exe.xyz, which the shared certificate does not
      # list as a principal — the name it is issued to is exe.dev, the front door
      # every one of these connections actually goes through. HostKeyAlias
      # verifies them under that name. No per-VM identity is given up, because
      # there is none to give up: the VMs do not have host keys of their own.
      "*.exe.xyz" = {
        # Every VM logs in as exedev; without this a bare `ssh <vm>.exe.xyz`
        # offers the local username and is refused after the host key verifies.
        User = "exedev";
        HostKeyAlias = "exe.dev";
      };

      "*" = {
        IdentityFile = "~/.ssh/dsok-pb";
        UserKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hosts_exedev";
      };
    };
  };
}
