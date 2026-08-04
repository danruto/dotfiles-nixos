{ pkgs-unstable, ... }:
{

  home.packages = with pkgs-unstable; [
    # aerospace
  ];

  # Config is the verbatim file from ./aerospace.toml.
  #
  # NOTE: AeroSpace reads ~/.aerospace.toml *in preference to* this path, so a
  # machine with a hand-written ~/.aerospace.toml will ignore what is deployed here.
  home.file.".config/aerospace/aerospace.toml".source = ./aerospace.toml;

  # [exec.env-vars]
  # PATH = '/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}'
}
