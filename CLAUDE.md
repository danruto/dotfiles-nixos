# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## System Information

This is a NixOS system using Nix Flakes and home-manager. If a CLI tool is missing, you can use `nix-shell -p <package-name>` to temporarily install it to run commands.

Example:
```bash
nix-shell -p wget --run "wget https://example.com"
```

## Per-host wiring

- `flake.nix` exposes **every** host simultaneously. There is no single "active profile" variable — build any host by name (`.#framework`, `.#orb`, `.#work`, …).
- Each host is one `mkSystem`/`mkHome` call taking `{ hostname; system; platform?; extraModules?; <identity overrides> }`. Identity defaults (`username`, `email`, `theme`, `wm`, `editor`, …) live in the `defaults` set in `flake.nix`.
- All flake inputs a host might need are threaded through one merged `baseSpecialArgs`. Nix is lazy, so unused inputs cost nothing — don't try to trim them per host.
- `config.local.nix` is **not** read by the flake. It only tells the `Makefile` which host `make switch` builds.
- Home-manager runs as a system module (`useGlobalPkgs`/`useUserPackages`) for owned NixOS/Darwin hosts, and standalone (`homeConfigurations`) for non-NixOS targets like orb-arch. Both import the same `hosts/<host>/home.nix`, differing only by the injected `platform` arg.
- Window manager config is split across `system/wm/` and `user/wm/` — check both when changing one.
