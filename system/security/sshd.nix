{ config, pkgs, username, ... }:

{
  # Enable incoming ssh
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  users.users.${username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGAczmC5uYv/lkslb9rYIqs2dFB5d5IrF0i2UZtgURjT danny@pixelbru.sh"
  ];
}
