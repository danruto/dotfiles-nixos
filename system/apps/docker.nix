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
    package = pkgs.docker_29;
    enableOnBoot = false;
    # storageDriver = storageDriver;
    # --volumes only removes anonymous volumes (Docker >= 23); named volumes are kept
    autoPrune = {
      enable = true;
      flags = [ "--all" "--volumes" ];
    };
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
