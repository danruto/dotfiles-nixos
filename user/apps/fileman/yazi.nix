{ ... }:
{
  programs.yazi = {
    enable = true;
    keymap = {
      mgr.append_keymap = [
        {
          run = [ "yank" "shell --block --interactive 'cp $1 '" "unyank" ];
          on = [ "R" ];
        }
      ];
    };
  };
}
