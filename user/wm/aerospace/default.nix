{ pkgs, ... }:
{

  home.packages = with pkgs.unstable; [
    aerospace
  ];

  #  ${XDG_CONFIG_HOME}/aerospace/aerospace.toml
  home.file.".config/aerospace/aerospace.toml".text = ''
    start-at-login = true

    [gaps]
    inner.horizontal = 0
    inner.vertical =   0
    outer.left =       4
    outer.bottom =     4
    outer.top =        4
    outer.right =      4

    [mode.main.binding]
    alt-1 = 'workspace 1'
    alt-2 = 'workspace 2'
    alt-3 = 'workspace 3'
    alt-4 = 'workspace 4'
    alt-5 = 'workspace 5'
    alt-6 = 'workspace 6'
    alt-7 = 'workspace 7'
    alt-8 = 'workspace 8'
    alt-9 = 'workspace 9'
    alt-0 = 'workspace 10'
    alt-a = 'workspace A'
    alt-b = 'workspace B'
    alt-c = 'workspace C'
    alt-d = 'workspace D'
    alt-e = 'workspace E'
    alt-f = 'workspace F'
    alt-g = 'workspace G'
    alt-i = 'workspace I'
    alt-m = 'workspace M'
    alt-n = 'workspace N'
    alt-o = 'workspace O'
    alt-p = 'workspace P'
    alt-q = 'workspace Q'
    alt-r = 'workspace R'
    alt-s = 'workspace S'
    alt-t = 'workspace T'
    alt-u = 'workspace U'
    alt-v = 'workspace V'
    alt-w = 'workspace W'
    alt-x = 'workspace X'
    alt-y = 'workspace Y'
    alt-z = 'workspace Z'
    alt-tab = 'workspace-back-and-forth'

    alt-shift-1 = 'move-node-to-workspace 1'
    alt-shift-2 = 'move-node-to-workspace 2'
    alt-shift-3 = 'move-node-to-workspace 3'
    alt-shift-4 = 'move-node-to-workspace 4'
    alt-shift-5 = 'move-node-to-workspace 5'
    alt-shift-6 = 'move-node-to-workspace 6'
    alt-shift-7 = 'move-node-to-workspace 7'
    alt-shift-8 = 'move-node-to-workspace 8'
    alt-shift-9 = 'move-node-to-workspace 9'
    alt-shift-a = 'move-node-to-workspace A'
    alt-shift-b = 'move-node-to-workspace B'
    alt-shift-c = 'move-node-to-workspace C'
    alt-shift-d = 'move-node-to-workspace D'
    alt-shift-e = 'move-node-to-workspace E'
    alt-shift-f = 'move-node-to-workspace F'
    alt-shift-g = 'move-node-to-workspace G'
    alt-shift-i = 'move-node-to-workspace I'
    alt-shift-m = 'move-node-to-workspace M'
    alt-shift-n = 'move-node-to-workspace N'
    alt-shift-o = 'move-node-to-workspace O'
    alt-shift-p = 'move-node-to-workspace P'
    alt-shift-q = 'move-node-to-workspace Q'
    alt-shift-r = 'move-node-to-workspace R'
    alt-shift-s = 'move-node-to-workspace S'
    alt-shift-t = 'move-node-to-workspace T'
    alt-shift-u = 'move-node-to-workspace U'
    alt-shift-v = 'move-node-to-workspace V'
    alt-shift-w = 'move-node-to-workspace W'
    alt-shift-x = 'move-node-to-workspace X'
    alt-shift-y = 'move-node-to-workspace Y'
    alt-shift-z = 'move-node-to-workspace Z'

    [[on-window-detected]]
    if.app-id = "com.mitchellh.ghostty"
    run = [
      # FIX: this is a workaround for https://github.com/nikitabobko/AeroSpace/issues/68
      # this was also observed in:
      # - https://github.com/ghostty-org/ghostty/issues/1840
      # - https://github.com/ghostty-org/ghostty/issues/2006
      "layout floating",
      "move-node-to-workspace T",
    ]
  '';

  # [exec.env-vars]
  # PATH = '/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}'
}
