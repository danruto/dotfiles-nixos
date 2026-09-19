# Theming is generated at runtime by scripts/theme-render (scripts/theme-set).
# Stylix targets are all off: the base16 YAML in themes/<name>/ is the only
# source of truth, and every app reads a file under ~/.local/state/theme.
#
# `vscode` is the one exception — its theme is a VS Code extension, which can't
# be swapped at runtime, so it still comes from the Stylix target and only
# updates on `theme-set --rebuild`.
{ config, lib, pkgs, ... }:

let
  state = config.xdg.stateHome;
  current = "${state}/theme/current";
  live = "${state}/theme/live";
  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  # One Spotlight/command-palette entry per theme. DMS indexes XDG desktop
  # entries, so Super+Space -> type "theme" -> Enter switches instantly via the
  # fast path. Adding a theme needs a rebuild to regenerate these entries.
  xdg.desktopEntries =
    let
      themeDir = ../themes;
      themeNames = builtins.attrNames (
        lib.filterAttrs
          (n: _: builtins.pathExists (themeDir + "/${n}/${n}.yaml"))
          (builtins.readDir themeDir)
      );
    in
    lib.genAttrs (map (n: "theme-${n}") themeNames) (slug:
      let name = lib.removePrefix "theme-" slug; in
      {
        name = "Theme: ${name}";
        comment = "Switch the theme to ${name}";
        # setsid so the switch survives theme-apply-live restarting DMS.
        exec = "${pkgs.util-linux}/bin/setsid -f ${config.home.homeDirectory}/dotfiles-nixos/scripts/theme-set ${name}";
        terminal = false;
        type = "Application";
        categories = [ "Settings" ];
        icon = "preferences-desktop-theme";
        settings.StartupNotify = "false";
      }
    );

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

  gtk = {
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
      name = "D2Koding Nerd Font";
      size = 12;
    };
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };

  qt = {
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
        fixed = ''"D2Koding Nerd Font,12"'';
        general = ''"D2Koding Nerd Font,12"'';
      };
    };
    qt6ctSettings = {
      Appearance = {
        custom_palette = true;
        standard_dialogs = "default";
        style = "kvantum";
      };
      Fonts = {
        fixed = ''"D2Koding Nerd Font,12"'';
        general = ''"D2Koding Nerd Font,12"'';
      };
    };
  };

  stylix.targets = {
    # vscode's theme is an extension and can't be swapped at runtime.
    vscode.enable = true;
  };
}
