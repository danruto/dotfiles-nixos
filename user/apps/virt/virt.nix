{ config, lib, pkgs, ... }:

{
  # Various packages related to virtualization, compatability and sandboxing
  home.packages = with pkgs; [
    # Virtual Machines and wine
    qemu
    uefi-run
    lxc
    swtpm
    # bottles

    buildkit
    docker-buildx
    # podman-compose
    # podman-tui

    # Filesystems
    # dosfstools
  ];

  home.file.".config/libvirt/qemu.conf".text = ''
    nvram = ["/run/libvirt/nix-ovmf/OVMF_CODE.fd:/run/libvirt/nix-ovmf/OVMF_VARS.fd"]
  '';

}
