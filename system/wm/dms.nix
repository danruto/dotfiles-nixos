{ ... }:
{
  # DMS provides its own polkit agent; disable niri-flake's default to avoid conflicts.
  systemd.user.services.niri-flake-polkit.enable = false;

  # The bar/launcher colors and wallpaper are supplied by
  # stylix.targets.dank-material-shell (user/theme.nix), which switches
  # currentThemeName to "custom" and writes the palette to customThemeFile.
}
