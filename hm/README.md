# Pure Home Manager config without NixOS

## Add current user to sudoers
```sh
vi /etc/sudoers
```

## Install nix using deterministic systems
```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
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

## Activate profile
```sh
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
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

## Install sway
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
mkdir ~/host
sudo mount -t 9p -o trans=virtio share ~/host
```
