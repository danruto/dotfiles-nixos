{ helix, pkgs, ... }:
{
  programs.helix = {
    enable = true;
    # package = pkgs.unstable.helix;
    package = helix.packages.${pkgs.system}.default;
    extraPackages = with pkgs; [
      nixpkgs-fmt
    ];
    defaultEditor = true;
    settings = {
      theme = "ayu_evolve";
      editor = {
        line-number = "relative";
        mouse = true;
        auto-info = true;
        true-color = true;
        color-modes = true;
        rulers = [ 120 ];
        text-width = 120;

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
        whitespace.render.tab = "all";
        whitespace.render.space = "all";
        whitespace.render.newline = "none";

        whitespace.characters = {
          space = "·";
          nbsp = "⍽";
          tab = "→";
          newline = "⏎";
          tabpad = "·";
        };

        popup-border = "all";

        statusline = {
          left = [ "mode" "spinner" ];
          center = [ "file-name" "file-modification-indicator" ];
          right = [ "version-control" "diagnostics" "selections" "position" "file-encoding" "file-line-ending" "file-type" "total-line-numbers" ];
        };
      };

      keys = {
        normal = {
          "{" = [ "goto_prev_paragraph" "collapse_selection" ];
          "}" = [ "goto_next_paragraph" "collapse_selection" ];
          "C-h" = [ "jump_view_left" "normal_mode" ];
          "C-l" = [ "jump_view_right" "normal_mode" ];
          "C-k" = [ "jump_view_up" "normal_mode" ];
          "C-j" = [ "jump_view_down" "normal_mode" ];
          "V" = [ "select_mode" "extend_to_line_bounds" ];
          "esc" = [ "collapse_selection" "keep_primary_selection" ];
          "K" = [ "hover" ];
        };

        select = {
          "{" = [ "extend_to_line_bounds" "goto_prev_paragraph" ];
          "}" = [ "extend_to_line_bounds" "goto_next_paragraph" ];
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
      language-server = {
        rust-analyzer = {
          config = {
            check = {
              command = "clippy";
            };
          };
        };

        ruff-lsp = {
          command = "ruff-lsp";
        };
      };

      language = [
        {
          name = "javascript";
          indent = { tab-width = 4; unit = "    "; };
          auto-format = true;
        }
        {
          name = "jsx";
          indent = { tab-width = 4; unit = "    "; };
          auto-format = true;
        }
        {
          name = "typescript";
          indent = { tab-width = 4; unit = "    "; };
          auto-format = true;
        }
        {
          name = "tsx";
          indent = { tab-width = 4; unit = "    "; };
          auto-format = true;
        }
        {
          name = "css";
          indent = { tab-width = 4; unit = "    "; };
          auto-format = true;
        }
        {
          name = "scss";
          indent = { tab-width = 4; unit = "    "; };
          auto-format = true;
        }
        {
          name = "json";
          indent = { tab-width = 4; unit = "    "; };
          auto-format = true;
        }
        {
          name = "yaml";
          indent = { tab-width = 4; unit = "    "; };
          auto-format = true;
        }
        {
          name = "html";
          indent = { tab-width = 4; unit = "    "; };
          auto-format = true;
        }
        {
          name = "rust";
          indent = { tab-width = 4; unit = "    "; };
          auto-format = true;
        }
        {
          name = "python";
          indent = { tab-width = 4; unit = "    "; };
          auto-format = true;
          language-servers = [ "ruff-lsp" "pyright" ];
        }
        {
          name = "nix";
          indent = { tab-width = 2; unit = "  "; };
          auto-format = true;
          formatter = { command = "nixpkgs-fmt"; };
        }
      ];
    };
  };


}
