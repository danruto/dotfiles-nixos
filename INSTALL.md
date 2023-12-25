#+title: Install
#+author: Danruto

These are just some simple install notes for myself (in-case I have to reinstall unexpectedly).

** Install Notes for Myself
To get this running on a NixOS system, start by cloning the repo:
#+BEGIN_SRC sh :noeval
git clone https://github.com/danruto/dotfiles-nixos.git ~/.dotfiles
#+END_SRC

To get the hardware configuration on a new system, either copy from =/etc/nixos/hardware-configuration.nix= or run:
#+BEGIN_SRC sh :noeval
cd ~/.dotfiles
sudo nixos-generate-config --show-hardware-config > system/hardware-configuration.nix
#+END_SRC

Also, if you have a differently named user account than my default (=danruto=), you /must/ update the following lines in the let binding near the top of the [[./flake.nix][flake.nix]]:
#+BEGIN_SRC nix :noeval
...
let
  ...
  # ----- USER SETTINGS ----- #
  username = "YOURUSERNAME"; # username
  name = "YOURNAME"; # name/identifier
...
#+END_SRC

There are many more config options there that you may also want to change as well.

Once the variables are set, then switch into the system configuration by running:
#+BEGIN_SRC sh :noeval
cd ~/.dotfiles
sudo nixos-rebuild switch --flake .#system
#+END_SRC

Home manager can be installed with:
#+BEGIN_SRC sh :noeval
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
#+END_SRC

If home-manager starts to not cooperate, it may be because the unstable branch of nixpkgs is in the Nix channel list.  This can be fixed via:
#+BEGIN_SRC sh :noeval
nix-channel --add https://nixos.org/channels/nixpkgs-unstable
nix-channel --update
#+END_SRC

Home-manager may also not work without re-logging back in after it has been installed.

Once home-manager is running, my home-manager configuration can be installed with:
#+BEGIN_SRC sh :noeval
cd ~/.dotfiles
home-manager switch --flake .#user
#+END_SRC
