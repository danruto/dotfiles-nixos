{ pkgs-unstable, username, ... }:

{
  home.packages = [ pkgs-unstable.cloudflared ];

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*.pixelbru.sh" = {
        proxyCommand = "${pkgs-unstable.cloudflared}/bin/cloudflared access ssh --hostname %h";
        user = username;
      };
    };
  };
}
