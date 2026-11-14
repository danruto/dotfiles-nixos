{ pkgs, ... }:
{
  # The 1Password SDK's desktop-app integration only dlopens
  # libop_sdk_ipc_client.so from fixed FHS paths, none of which exist on NixOS.
  systemd.tmpfiles.rules = [
    "L+ /opt/1Password - - - - ${pkgs._1password-gui}/share/1password"
  ];
}
