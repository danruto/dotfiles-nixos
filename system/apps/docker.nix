{ config, lib, pkgs, username, storageDriver ? null, ... }:

# assert lib.asserts.assertOneOf "storageDriver" storageDriver [
#   null
#   "aufs"
#   "btrfs"
#   "devicemapper"
#   "overlay"
#   "overlay2"
#   "zfs"
# ];

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    # storageDriver = storageDriver;
    autoPrune.enable = true;
  };
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune.enable = true;
  };

  # services.docker.settings = {
  #   features = {
  #     buildkit = true;
  #   };
  # };

  # users.users.${username}.extraGroups = [ "docker" ];
}
