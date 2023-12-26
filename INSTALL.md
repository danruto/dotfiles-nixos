# Pre-req
- Download (the latest NixOS-WSL installer)[https://github.com/nix-community/NixOS-WSL]
- Install it `wsl --import NixOS .\NixOS\ .\nixos-wsl.tar.gz --version 2`

# Setup
## Install and update the packages channel
```sh
sudo nix-channel --add https://nixos.org/channels/nixos-23.11 nixos
sudo nix-channel --update
```

## Fetch this repo and build the NixOS baseline
```sh
nix-shell -p git helix
git clone https://github.com/danruto/dotfiles-nixos.git /tmp/configuration
cd /tmp/configuration
```

## Install it
```sh
sudo nixos-rebuild switch --flake .#system
```

## Exit and reconnect once system installed
```sh
exit
wsl -t NixOS
wsl -d NixOS
```

## Move the config into home dir
```sh
mv /tmp/configuration ~/configuration
```

## Setup home-manager
```sh
cd ~/configuration
sudo nixos-rebuild switch --flake .#system
home-manager switch --flake .#user
```
> NOTE: If it errors with `Could not find suitable profile directory` then run `nix profile list` and it should fix it
