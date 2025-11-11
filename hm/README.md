# Pure Home Manager config without NixOS

## Add current user to sudoers
```sh
vi /etc/sudoers
```

## Install nix using deterministic systems
```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

## Activate profile
```sh
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

## Add home manager channels
```sh
nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
nix-channel --update
```

## Install home manager
```sh
nix-shell '<home-manager>' -A install
```

## Shell git and make (if required)
```sh
nix-shell -p git gnumake
```

## Install our configs
```sh
make hmr
```

## Set fish as main shell
```sh
sudo nvim /etc/shells add /home/danruto/.nix-profile/bin/fish
chsh -s /home/danruto/.nix-profile/bin/fish
```

## Install sway (if required)
```
  sudo apt install sway
```

Now reboot and choose `Sway` from SDDM. All should work as expected now.

## Mount UTM Share
```sh
sudo apt install spice-vdagent spice-webdavd davfs2
```

```sh
mkdir ~/host
sudo vi /etc/fstab
# share /home/danruto/host 9p trans=virtio,rw,nofail 0 0
```
or
```sh
# mkdir ~/host
# sudo mount -t 9p -o trans=virtio share ~/host
sudo mkdir /mnt/utm
sudo mount -t virtiofs share /mnt/utm
```
or
```sh
sudo vi /etc/fstab
# share /mnt/utm 9p trans=virtio,version=9p2000.L,rw,_netdev,nofail,auto 0 0
# /mnt/utm /home/user/utm fuse.bindfs map=502/1000:@20/@1000,x-systemd.requires=/mnt/utm,_netdev,nofail,auto 0 0

systemctl daemon-reload
systemctl restart network-fs.target # use remote-fs.target if not found
systemctl list-units --type=mount

```
