{ pkgs-unstable, username, ... }:

{
  home.packages = [ pkgs-unstable.cloudflared ];

  # home-manager owns ~/.ssh/config when programs.ssh.enable = true,
  # so any "global" defaults must live here as a Host * matchBlock.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*.pixelbru.sh" = {
        ProxyCommand = "${pkgs-unstable.cloudflared}/bin/cloudflared access ssh --hostname %h";
        User = username;
      };

      "*" = {
        IdentityFile = "~/.ssh/dsok-pb";
      };
    };
  };
}
