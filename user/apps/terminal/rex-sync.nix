{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;
  cfg = config.local.rexSync;
in
{
  options.local.rexSync.rexBin = lib.mkOption {
    type = lib.types.str;
    description = "The rex CLI the sync and status services run.";
  };

  config = {
    # Same live-linked config as the Mac (rex-app.nix): this server's clients get
    # the herdr keys and actions, and hc-rex-sync runs from the working tree.
    home.file.".config/rex".source =
      config.lib.file.mkOutOfStoreSymlink "${home}/dotfiles-nixos/user/apps/terminal/configs/rex";

    # Mirrors herdr-app's spaces, tabs and splits into Rex and back.
    systemd.user.services.hc-rex-sync = {
      Unit.Description = "Sync herdr-app's layout with Rex";
      Service = {
        ExecStart = "${pkgs.nodejs}/bin/node ${home}/.config/rex/hc-rex-sync.mjs";
        Environment = [
          "PATH=${dirOf cfg.rexBin}:/etc/profiles/per-user/${config.home.username}/bin:${home}/.nix-profile/bin:${home}/.local/bin:/run/current-system/sw/bin:/usr/bin:/bin"
        ];
        Restart = "always";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };

    # Tab status emoji, as launchd runs it on the Mac. `rex do` exits when the
    # server restarts; systemd starts it again.
    systemd.user.services.rex-status = {
      Unit.Description = "Rex tab status emoji";
      Service = {
        ExecStart = "${cfg.rexBin} do --all ${home}/.config/rex/status.lua";
        Restart = "always";
        RestartSec = 10;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
