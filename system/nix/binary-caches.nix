# Shared binary caches so community packages (neovim-nightly, hyprland, and
# other nix-community outputs) are substituted instead of built from source.
# Imported by every NixOS host via lib/mkSystem.nix, so it applies universally
# rather than per-host. cache.nixos.org is a default; the FlakeHub/Determinate
# caches come from the Determinate installer's own nix.conf.
#
# NOTE: standalone/Determinate targets (e.g. orb-arch via `make hm/switch`) are
# NOT covered by this NixOS module — their daemon reads /etc/nix/nix.custom.conf
# instead. Add the same two caches there.
{ ... }:
{
  nix.settings.extra-substituters = [
    "https://nix-community.cachix.org"
    "https://hyprland.cachix.org"
  ];
  nix.settings.extra-trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
  ];
}
