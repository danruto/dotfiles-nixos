{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.quickshell;
in
{
  options.programs.quickshell = {
    enable = mkEnableOption "quickshell";

    package = mkOption {
      type = types.package;
      default = pkgs.quickshell or (throw "quickshell package not found in pkgs");
      description = "The quickshell package to use";
    };

    configs = mkOption {
      type = types.attrs;
      default = { };
      description = "Quickshell configurations";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
