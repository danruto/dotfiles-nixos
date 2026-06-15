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

- **`flake.nix`** - Central hub. Exposes **every** host simultaneously via `mkSystem`/`mkHome` calls: `nixosConfigurations.<host>`, `darwinConfigurations.<host>`, `homeConfigurations.<user@host>`. No single "active profile" variable — build any host by name (`.#framework`, `.#orb`, `.#work`, …).
- **`lib/`** - Wiring helpers: `mkPkgs.nix` (one nixpkgs/unstable/master instance per system), `overlays.nix` (shared overlay lists), `mkSystem.nix` (nixos+darwin builder, dispatches on `platform`), `mkHome.nix` (standalone home builder).
- **`hosts/`** - Per-host entrypoints, each containing `configuration.nix` and `home.nix` (+ `hardware-configuration.nix` for bare-metal/VM). Hosts: framework, wsl, orb, vm variants, work/work2/nearmap (darwin), orb-arch (standalone home).
- **`system/`** - System-wide NixOS/Darwin modules (hardware, security, window managers, apps)
- **`user/`** - User-specific home-manager modules (applications, shell, languages, themes)
- **`themes/`** - Color schemes and visual themes

### Per-host wiring
Each host is one `mkSystem`/`mkHome` call in `flake.nix` taking `{ hostname; system; platform?; extraModules?; <identity overrides> }`. Identity defaults (`username`, `email`, `theme`, `wm`, `editor`, …) live in the `defaults` set in `flake.nix` and are overridable per host. All flake inputs a host might need are threaded through one merged `baseSpecialArgs` (Nix is lazy, so unused inputs cost nothing). `config.local.nix` is no longer read by the flake — it only tells the `Makefile` which host `make switch` should build.

### Module System Architecture
- **System modules** (`system/`) are imported into NixOS/Darwin configuration
- **User modules** (`user/`) are managed by home-manager
- **Shared configuration** (`hosts/shared.nix`) provides common user settings
- Home-manager runs as a system module (`useGlobalPkgs`/`useUserPackages`) for owned NixOS/Darwin hosts, and standalone (`homeConfigurations`) for non-NixOS targets like orb-arch. Both import the same `hosts/<host>/home.nix`, differing only by the injected `platform` arg.
- Window manager configurations exist in both `system/wm/` and `user/wm/` for system and user-level settings

### Multi-Platform Support
- **NixOS** - Primary target with full system configuration
- **macOS** - Darwin configurations for work setups using nix-darwin
- **WSL** - Windows Subsystem for Linux support via nixos-wsl

## Development Workflow

When modifying configurations:

1. Edit relevant modules in `system/` or `user/` directories
2. For new hosts, add a `hosts/<host>/` dir and a `mkSystem`/`mkHome` call in `flake.nix`
3. Test changes with `nixos-rebuild dry-run` before applying
4. Use `make switch` to apply system-wide changes (builds the host named in `config.local.nix`)
5. Use `home-manager switch --flake ".#user"` for user-only changes

The configuration supports both stable (nixos-26.05) and unstable (nixos-unstable) package channels, with unstable packages available via `pkgs-unstable` in modules.

## Neovim / Treesitter

- Uses **neovim-nightly-overlay** with **post-rewrite nvim-treesitter** from pkgs-unstable
- **DO NOT** use `require("nvim-treesitter.configs").setup()` — this module was removed in the nvim-treesitter rewrite. The modern API uses `vim.treesitter.start(buf)` via FileType autocmds (see `coding.lua`)
- Treesitter queries live at `${nvim-treesitter}/runtime/queries/`, not at the plugin root
- RTP prepend for treesitter must happen in `initLua` BEFORE `lazy.setup()` — `plugin/` files run too late
- Parsers come from `allGrammars` symlinked to `~/.config/nvim/parser/`