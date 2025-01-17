{ ... }:
{
  programs.yazi = {
    enable = true;
    keymap = {
      manager.append_keymap = [
        {
          run = [ "yank" "shell --block --interactive 'cp $1 '" "unyank" ];
          on = [ "R" ];
        }
      ];
    };
  };
}
