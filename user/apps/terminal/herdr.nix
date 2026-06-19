{ pkgs, config, herdr, ... }:
{
  home.packages = [ herdr.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  # herdr writes back to config.toml at runtime (theme/sound/agent-view toggles,
  # onboarding=false). A read-only nix-store symlink makes those writes fail, so
  # point the symlink at the live working-tree copy instead — herdr's edits land
  # directly in this repo (commit or discard them as you like). Assumes the repo
  # is checked out at ~/dotfiles-nixos; adjust the subpath if a host clones it
  # elsewhere.
  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles-nixos/user/apps/terminal/configs/herdr/config.toml";
}
