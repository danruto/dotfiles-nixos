# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## System Information

This is a NixOS system using Nix Flakes and home-manager. If a CLI tool is missing, you can use `nix-shell -p <package-name>` to temporarily install it to run commands.

Example:
```bash
nix-shell -p wget --run "wget https://example.com"
```

## Common Commands

### System Management
- `make switch` - Main command to rebuild and switch NixOS system configuration
- `sudo nixos-rebuild switch --flake ".#system" --show-trace` - Direct NixOS rebuild command
- `home-manager switch --flake ".#user"` - Apply home-manager configuration changes
- `nix flake update` - Update all flake inputs to latest versions
- `nix-collect-garbage -d` - Clean up old generations and free disk space

### Development and Testing
- `nix build --extra-experimental-features nix-command --extra-experimental-features flakes` - Build configurations
- `nixos-rebuild dry-run --flake ".#system"` - Test configuration without applying changes
- `nix flake check` - Validate flake configuration syntax

### VM Development (when NIXADDR is set)
- `make vm/copy` - Copy configuration to remote VM
- `make vm/switch` - Apply configuration to remote VM
- `make vm/bootstrap/0` - Initial VM setup with disk partitioning
- `make vm/bootstrap/1` - Apply system configuration to VM
- `make vm/bootstrap/2` - Apply home-manager configuration to VM

## Architecture Overview

### Configuration Structure
This is a modular NixOS configuration using Nix Flakes with clear separation of concerns:

- **`flake.nix`** - Central configuration hub defining system settings, user preferences, and active profile
- **`profiles/`** - Host-specific configurations, each containing `configuration.nix` and `home.nix`
  - Current active profile is defined by the `profile` variable in `flake.nix:32`
  - Profiles include: framework, wsl, vm variants, work setups, orb
- **`system/`** - System-wide NixOS modules (hardware, security, window managers, apps)
- **`user/`** - User-specific home-manager modules (applications, shell, languages, themes)
- **`themes/`** - Color schemes and visual themes

### Key Configuration Variables
The main system configuration is controlled by variables in `flake.nix` lines 24-46:
- `system` - Target architecture (currently x86_64-linux)
- `profile` - Active configuration profile (currently "framework")
- `hostname`, `username`, `email` - System identity
- `theme` - Active color theme from themes/ directory
- `wm` - Window manager (hyprland/niri)
- `browser`, `editor`, `term` - Default applications

### Module System Architecture
- **System modules** (`system/`) are imported into NixOS configuration
- **User modules** (`user/`) are managed by home-manager
- **Shared configuration** (`profiles/shared.nix`) provides common user settings
- Window manager configurations exist in both `system/wm/` and `user/wm/` for system and user-level settings

### Multi-Platform Support
- **NixOS** - Primary target with full system configuration
- **macOS** - Darwin configurations for work setups using nix-darwin
- **WSL** - Windows Subsystem for Linux support via nixos-wsl

## Development Workflow

When modifying configurations:

1. Edit relevant modules in `system/` or `user/` directories
2. For new hosts, create profile in `profiles/` and update `flake.nix` profile variable
3. Test changes with `nixos-rebuild dry-run` before applying
4. Use `make switch` to apply system-wide changes
5. Use `home-manager switch --flake ".#user"` for user-only changes

The configuration supports both stable (nixos-25.05) and unstable (nixos-unstable) package channels, with unstable packages available via `pkgs-unstable` in modules.