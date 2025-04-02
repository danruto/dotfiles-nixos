{ pkgs, font, ... }:
{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        # font = "IosevkaComfy:size=14";
        font = "DepartureMono:size=12";
      };
      mouse = {
        hide-when-typing = "yes";
      };
      csd = {
        size = 0;
      };
    };
  };

}
