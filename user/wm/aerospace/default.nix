{ ... }:
{
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

  '';

  # [exec.env-vars]
  # PATH = '/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}'
}
