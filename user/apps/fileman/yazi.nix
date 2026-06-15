{ ... }:
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "yy";
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
