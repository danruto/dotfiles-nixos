{ config, lib, pkgs, ... }:

let
  stable-packages = with pkgs; [
    killall
    libnotify
    bat 
    eza 
    fd 
    gotop
    rsync
    hwinfo
    unzip
    brightnessctl
    fzf
    pandoc
    pciutils
    tree-sitter
    xh
    tealdeer
  ];
  unstable-packages = with pkgs.unstable; [
    ripgrep
    neovim
		# helix
    ani-cli
    yt-dlp
  ];
in
{
  home.packages = stable-packages 
                ++ unstable-packages
                ++ [
                  (pkgs.writeShellScriptBin "airplane-mode" ''
                    #!/bin/sh
                    connectivity="$(nmcli n connectivity)"
                    if [ "$connectivity" == "full" ]
                    then
                        nmcli n off
                    else
                        nmcli n on
                    fi
                  '')
                ];

  imports = [
  ];

  programs.helix = {
    enable = true;
    package = pkgs.unstable.helix;
    defaultEditor = true;
    settings = {
      theme = "ayu_evolve";
      editor = {
        line-number = "relative";
        mouse = true;
        auto-info = true;
        true-color = true;
        color-modes = true;
        rulers = [120];

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        file-picker = {
          hidden = false;
        };

        lsp = {
          display-inlay-hints = true;
          display-messages = true;
        };

        indent-guides.render = true;
        
        statusline = {
          left = ["mode" "spinner"];
          center = ["file-name" "file-modification-indicator"];
          right = ["version-control" "diagnostics" "selections" "position" "file-encoding" "file-line-ending" "file-type" "total-line-numbers"];
        };
      };

      keys = {
        normal = {
          "{" = ["goto_prev_paragraph" "collapse_selection"];
          "}" = ["goto_next_paragraph" "collapse_selection"];
          "C-h" = ["jump_view_left" "normal_mode"];
          "C-l" = ["jump_view_right" "normal_mode"];
          "C-k" = ["jump_view_up" "normal_mode"];
          "C-j" = ["jump_view_down" "normal_mode"];
          "V" = ["select_mode" "extend_to_line_bounds"];
          "esc" = ["collapse_selection" "keep_primary_selection"];
          "K" = ["hover"];
        };

        select = {
          "{" = ["extend_to_line_bounds" "goto_prev_paragraph"];
          "}" = ["extend_to_line_bounds" "goto_next_paragraph"];
        };

        insert = {
          up = "move_line_up";
          down = "move_line_down";
          left = "move_char_left";
          right = "move_char_right";
        };
      };
    };

    languages = {
      language = [
        {
          name = "javascript";
          indent = { tab-width = 4; unit = "    "; };
        }
        {
          name = "jsx";
          indent = { tab-width = 4; unit = "    "; };
        }
        {
          name = "typescript";
          indent = { tab-width = 4; unit = "    "; };
        }
        {
          name = "tsx";
          indent = { tab-width = 4; unit = "    "; };
        }
        {
          name = "css";
          indent = { tab-width = 4; unit = "    "; };
        }
        {
          name = "scss";
          indent = { tab-width = 4; unit = "    "; };
        }
        {
          name = "json";
          indent = { tab-width = 4; unit = "    "; };
        }
        {
          name = "html";
          indent = { tab-width = 4; unit = "    "; };
        }
        {
          name = "rust";
          indent = { tab-width = 4; unit = "    "; };
        }
      ];
    };
  };

}
