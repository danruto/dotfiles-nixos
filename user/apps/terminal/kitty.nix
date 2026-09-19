{ pkgs, pkgs-unstable, config, ... }:

# Font here; colours come from the runtime include, rewritten by
# scripts/theme-render on every switch (it wins by being last).
{
  programs.kitty = {
    enable = true;
    package = pkgs-unstable.kitty;
    font = {
      package = pkgs.d2coding;
      name = "D2Koding Nerd Font";
      size = 14;
    };
    extraConfig = builtins.readFile ./configs/kitty/kitty.conf + ''
      include ${config.home.homeDirectory}/.local/state/theme/current/kitty.conf
    '';
  };
}
