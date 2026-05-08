{ pkgs-unstable, username, ... }:

{
  home.packages = [ pkgs-unstable.cloudflared ];

  # home-manager owns ~/.ssh/config when programs.ssh.enable = true,
  # so any "global" defaults must live here as a Host * matchBlock.
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*.pixelbru.sh" = {
        proxyCommand = "${pkgs-unstable.cloudflared}/bin/cloudflared access ssh --hostname %h";
        user = username;
      };

      "*" = {
        identityFile = "~/.ssh/dsok-pb";
      };
    };
  };
}
