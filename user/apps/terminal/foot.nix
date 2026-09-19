{ pkgs, config, ... }:
{
  # Colors, alpha and font come from stylix.targets.foot (user/theme.nix).
  # The runtime include is rewritten by scripts/theme-render on every theme
  # switch, so colors change without a rebuild.
  programs.foot = {
    enable = true;
    settings = {
      main.include = "${config.home.homeDirectory}/.local/state/theme/current/foot.ini";
      main.font = "D2Koding Nerd Font:size=14";
      main.dpi-aware = "no";
      mouse = {
        hide-when-typing = "yes";
      };
      csd = {
        size = 0;
      };
    };
  };
}
