MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

NIXADDR ?= unset
NIXPORT ?= 22

# Same as inside `flake.nix`
NIXUSER ?= danruto

# Auto-detect profile from config.local.nix (if exists) or flake.nix
PROFILE := $(shell \
	if [ -f config.local.nix ]; then \
		grep 'profile = ' config.local.nix | sed -E 's/.*profile = "([^"]+)".*/\1/'; \
	else \
		grep 'profile = ' flake.nix | head -1 | sed -E 's/.*profile = "([^"]+)".*/\1/'; \
	fi)

SSH_OPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
UNAME := $(shell uname)
ARCH := $(shell uname -m)

help:
	@echo "Detected configuration:"
	@echo "  Profile: $(PROFILE)"
	@echo "  OS: $(UNAME)"
	@echo "  Architecture: $(ARCH)"
ifeq ($(UNAME), Darwin)
ifeq ($(ARCH), arm64)
	@echo "  Will use: darwinConfigurations.$(PROFILE)"
else
	@echo "  Will use: darwinConfigurations.$(PROFILE)-x86"
endif
else
	@echo "  Will use: nixosConfigurations.system"
endif
	@echo ""
	@echo "Available targets:"
	@echo "  make switch - Build and switch to the detected configuration"
	@echo "  make help   - Show this help message"

vm/help:
	echo "sudo -i; passwd. Set to root."
	echo "export NIXADDR = $(ifconfig of vm); make vm/bootstrap/$(step)"

# Bootstrap based on: https://github.com/mitchellh/nixos-config/blob/main/Makefile
vm/bootstrap/0:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) root@$(NIXADDR) " \
		parted /dev/sda -- mklabel gpt; \
		parted /dev/sda -- mkpart primary 512MB -8GB; \
		parted /dev/sda -- mkpart primary linux-swap -8GB 100\%; \
		parted /dev/sda -- mkpart ESP fat32 1MB 512MB; \
		parted /dev/sda -- set 3 esp on; \
		sleep 1; \
		mkfs.ext4 -L nixos /dev/sda1; \
		mkswap -L swap /dev/sda2; \
		mkfs.fat -F 32 -n boot /dev/sda3; \
		sleep 1; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-generate-config --root /mnt; \
		sed --in-place '/system\.stateVersion = .*/a \
			# nix.package = pkgs.git;\n \
			nix.extraOptions = \"experimental-features = nix-command flakes\";\n \
			services.openssh.enable = true;\n \
			services.openssh.settings.PasswordAuthentication = true;\n \
			services.openssh.settings.PermitRootLogin = \"yes\";\n \
			users.users.root.initialPassword = \"root\";\n \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --no-root-passwd && shutdown -h now; \
	"

vm/bootstrap/1:
	NIXUSER=root $(MAKE) vm/copy
	# NIXUSER=root $(MAKE) vm/git_update
	NIXUSER=root $(MAKE) vm/switch
	$(MAKE) vm/secrets
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo reboot; \
	"

vm/bootstrap/2:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		nix profile list; \
		home-manager switch -b backup --flake /nix-config#user; \
	"

vm/bootstrap/u:
	NIXUSER=root $(MAKE) vm/copy
	NIXUSER=root $(MAKE) vm/switch

# copy our secrets into the VM
vm/secrets:
	# SSH keys
	rsync -av -e 'ssh $(SSH_OPTIONS)' \
		--exclude='environment' \
		$(HOME)/.ssh/ $(NIXUSER)@$(NIXADDR):~/.ssh
	rsync -av -e 'ssh $(SSH_OPTIONS)' \
		--exclude='environment' \
		$(HOME)/.config/gh/ $(NIXUSER)@$(NIXADDR):~/.config/gh

# copy the Nix configurations into the VM.
vm/copy:
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
		--exclude='vendor/' \
		--exclude='.git/' \
		--exclude='.git-crypt/' \
		--exclude='iso/' \
		--rsync-path="sudo rsync" \
		$(MAKEFILE_DIR)/ $(NIXUSER)@$(NIXADDR):/nix-config
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
	    cp /etc/nixos/hardware-configuration.nix /nix-config/profiles/$(PROFILE) \
	"

vm/git_update:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
	    cd /nixos-config; git add --all; \
	"

# run the nixos-rebuild switch command. This does NOT copy files so you
# have to run vm/copy before.
vm/switch:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --flake \"/nix-config#system\" --show-trace \
	"

vm/ssh:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR)

switch:
ifeq ($(UNAME), Darwin)
	@echo "Building for profile: $(PROFILE) on $(UNAME) $(ARCH)"
ifeq ($(ARCH), arm64)
	@echo "Using ARM64 (Apple Silicon) configuration"
	nix build ".#darwinConfigurations.$(PROFILE).system" --show-trace
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#$(PROFILE)"
else
	@echo "Using x86_64 (Intel) configuration"
	nix build ".#darwinConfigurations.$(PROFILE)-x86.system" --show-trace
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#$(PROFILE)-x86"
endif
else
	@echo "Building for profile: $(PROFILE) on NixOS"
	sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --flake ".#system" --show-trace
endif

norb:
	sudo nixos-rebuild switch --flake .#system

.PHONY: help switch norb vm/help vm/bootstrap/0 vm/bootstrap/1 vm/bootstrap/2 vm/bootstrap/u vm/secrets vm/copy vm/git_update vm/switch vm/ssh
