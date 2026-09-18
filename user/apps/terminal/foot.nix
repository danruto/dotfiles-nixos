{ pkgs, ... }:
{
  # Colors, alpha and font come from stylix.targets.foot (user/theme.nix).
  # Only non-themed behaviour stays here.
  programs.foot = {
    enable = true;
    settings = {
      mouse = {
        hide-when-typing = "yes";
      };
      csd = {
        size = 0;
      };
    };
  };
}
