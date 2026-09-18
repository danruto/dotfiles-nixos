# Stylix targets. autoEnable is off in system/theme.nix, so each app is opted
# in here once its hand-written theming has been checked for conflicts.
#
# Targets enabled here follow the theme switch (scripts/theme-set + live
# apply). Apps with no Stylix target keep their own hand-written config.
{
  stylix.targets = {
    bat.enable = true;
    btop.enable = true;
    fish.enable = true;
    fzf.enable = true;
    gitui.enable = true;
    starship.enable = true;
    yazi.enable = true;

    # Terminals. kitty and foot no longer ship hand-written colors, so the
    # generated palette is the only source.
    foot.enable = true;
    kitty.enable = true;
    ghostty.enable = true;

    # Desktop shell + launcher. DMS also takes the Stylix wallpaper here.
    dank-material-shell.enable = true;
    vicinae.enable = true;

    # Editors / GUI toolkits.
    helix.enable = true;
    gtk.enable = true;
    qt.enable = true;
    vscode.enable = true;
    opencode.enable = true;

    # hyprland border colors now read config.lib.stylix.colors directly in
    # user/wm/hyprland/hyprland.nix; leave the target off to avoid fighting it.
    hyprland.enable = false;
  };
}
