# Theming is generated at runtime by scripts/theme-render (scripts/theme-set).
# Stylix targets are all off: the base16 YAML in themes/<name>/ is the only
# source of truth, and every app reads a file under ~/.local/state/theme.
#
# `vscode` is the one exception — its theme is a VS Code extension, which can't
# be swapped at runtime, so it still comes from the Stylix target and only
# updates on `theme-set --rebuild`.
{ config, lib, pkgs, platform ? "nixos", ... }:

let
  state = config.xdg.stateHome;
  current = "${state}/theme/current";
  live = "${state}/theme/live";
  link = config.lib.file.mkOutOfStoreSymlink;
  # Standalone hosts (orb-arch) are headless: no session bus for the gtk
  # module's dconf writes, and no GUI to theme.
  desktop = platform != "standalone";
in
{
  # One command-palette entry per theme is generated at runtime by
  # scripts/theme-entries (into $XDG_DATA_HOME/applications) so launchers see
  # themes as soon as they are added, with no rebuild. Regenerate on activation
  # so a fresh install that has never run theme-set still has entries.
  # Headless standalone hosts have no launcher, so skip it there.
  home.activation.themeEntries = lib.mkIf desktop (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    entry_script="${config.home.homeDirectory}/dotfiles-nixos/scripts/theme-entries"
    if [ -x "$entry_script" ]; then
      $DRY_RUN_CMD "$entry_script" >/dev/null
    fi
  '');

  # Runtime theme files, out-of-store so a symlink swap is enough.
  xdg.configFile = {
    "gitui/theme.ron" = lib.mkForce {
      source = link "${current}/gitui-theme.ron";
    };
    "gtk-3.0/gtk.css" = lib.mkForce { source = link "${current}/gtk-3.0/gtk.css"; };
    "gtk-4.0/gtk.css" = lib.mkForce { source = link "${current}/gtk-4.0/gtk.css"; };
    "yazi/theme.toml" = lib.mkForce { source = link "${current}/yazi-theme.toml"; };
    "bat/themes/base16-stylix.tmTheme" = lib.mkForce {
      source = link "${current}/bat.tmTheme";
    };
    "helix/themes/stylix.toml" = lib.mkForce {
      source = link "${current}/helix-theme.toml";
    };
    "Kvantum/Base16Kvantum/Base16Kvantum.kvconfig" = {
      source = link "${current}/Kvantum/Base16Kvantum/Base16Kvantum.kvconfig";
    };
    "Kvantum/Base16Kvantum/Base16Kvantum.svg" = {
      source = link "${current}/Kvantum/Base16Kvantum/Base16Kvantum.svg";
    };
  };

  # Fonts previously came from stylix.fonts.
  programs.fish.interactiveShellInit = lib.mkAfter ''
    test -r ${live}/fish.fish; and source ${live}/fish.fish
  '';
  home.sessionVariables.STARSHIP_CONFIG = lib.mkForce "${live}/starship.toml";

  # bat also rebuilds its cache on activation (its own home.activation);
  # theme-apply-live rebuilds it again on every runtime switch.
  programs.bat.config.theme = "base16-stylix";

  gtk = lib.mkIf desktop {
    enable = true;
    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3";
    };
    gtk4.theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3";
    };
    font = {
      package = pkgs.d2coding;
      name = "D2KodingLigature Nerd Font";
      size = 12;
    };
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };

  qt = lib.mkIf desktop {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
    kvantum = {
      enable = true;
      settings.General.theme = "Base16Kvantum";
    };
    qt5ctSettings = {
      Appearance = {
        custom_palette = true;
        standard_dialogs = "default";
        style = "kvantum";
      };
      Fonts = {
        fixed = ''"D2KodingLigature Nerd Font,12"'';
        general = ''"D2KodingLigature Nerd Font,12"'';
      };
    };
    qt6ctSettings = {
      Appearance = {
        custom_palette = true;
        standard_dialogs = "default";
        style = "kvantum";
      };
      Fonts = {
        fixed = ''"D2KodingLigature Nerd Font,12"'';
        general = ''"D2KodingLigature Nerd Font,12"'';
      };
    };
  };

  stylix.targets = {
    # vscode's theme is an extension and can't be swapped at runtime.
    vscode.enable = true;
  };
}
