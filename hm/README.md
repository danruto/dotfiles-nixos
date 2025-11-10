# Pure Home Manager config without NixOS

## Installation
Install nix. If you forget use zerotonix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
nix-channel --update

nix-shell '<home-manager>' -A install



For debian might need to add /usr/sbin to path e.g. ``
Add user to `/etc/sudoers`
The `sudo` to install nix

Go back to regular user to install home manager: ``

Clone this repo into `~/.config/home-manager`

Then run make bin

Also need to manually set shell

sudo nvim /etc/shells add /home/danruto/.nix-profile/bin/fish
chsh -s /home/danruto/.nix-profile/bin/fish

install sway manually with sudo apt install sway
