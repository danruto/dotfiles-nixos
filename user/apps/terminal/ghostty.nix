{ config, ... }:
{
  # font-family = "Departure Mono"
  # font-family = "Iosevka Comfy"
  # Symlinked out-of-store so edits to the config file below take effect
  # immediately without a rebuild.
  home.file.".config/ghostty/config".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles-nixos/user/apps/terminal/ghostty/config";
}
