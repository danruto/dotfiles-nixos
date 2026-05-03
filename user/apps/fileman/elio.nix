{ pkgs-unstable, ... }:
let
  elio = pkgs-unstable.callPackage ./elio-pkg.nix { };
in
{
  home.packages = [ elio ];

  # TODO(user): elio reads ~/.config/elio/config.toml. Decide whether to
  # manage it declaratively here (mirroring yazi.nix's keymap override),
  # or leave config un-managed so it can be edited by hand.
  #
  # xdg.configFile."elio/config.toml".text = ''
  # '';
}
