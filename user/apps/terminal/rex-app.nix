{ config, ... }:
{
  # Linked to the working tree so edits apply with `rex config reload`, without
  # a rebuild. Assumes the repo is checked out at ~/dotfiles-nixos.
  # The whole folder is linked because init.lua requires herdr.lua beside it.
  home.file.".config/rex".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles-nixos/user/apps/terminal/configs/rex";

  # Tab status emoji. Rex ships its CLI inside the app bundle, not on PATH.
  # `rex do` exits when the server restarts; launchd starts it again.
  launchd.agents.rex-status = {
    enable = true;
    config = {
      ProgramArguments = [
        "/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex"
        "do" "--all" "${config.home.homeDirectory}/.config/rex/status.lua"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/rex-status.log";
    };
  };
}
