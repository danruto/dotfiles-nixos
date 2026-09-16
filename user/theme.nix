# Stylix targets. autoEnable is off in system/theme.nix, so each app is opted
# in here once its hand-written theming has been checked for conflicts.
#
# Blocked on removing existing config first (each would be a duplicate
# definition of an option already set by hand):
#   gtk     -> hosts/framework/home.nix sets gtk.theme / gtk.iconTheme
#   helix   -> user/apps/terminal/helix-fork.nix sets theme = "flexoki_dark"
#   kitty   -> user/apps/terminal/kitty.nix ships a verbatim kitty.conf
#   zellij  -> user/apps/terminal/zellij.nix ships a verbatim config.kdl
#   foot    -> user/apps/terminal/foot.nix pins main.font
{
  stylix.targets = {
    bat.enable = true;
    btop.enable = true;
    fish.enable = true;
    fzf.enable = true;
    gitui.enable = true;
    starship.enable = true;
    yazi.enable = true;
  };
}
