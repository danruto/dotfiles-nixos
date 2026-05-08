{ pkgs-unstable, ... }:
{

  home.packages = with pkgs-unstable; [
    # miri
  ];

  # ${XDG_CONFIG_HOME}/miri/config.json
  home.file.".config/miri/config.json".source = ./config.json;
}
