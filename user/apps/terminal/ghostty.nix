{ config, ... }:
{
  # Colors, font and cursor come from stylix.targets.ghostty (user/theme.nix).
  # This file overlays presentation behaviour only. It is symlinked
  # out-of-store so edits take effect without a rebuild.
  home.file.".config/ghostty/config".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles-nixos/user/apps/terminal/ghostty/config";
}
