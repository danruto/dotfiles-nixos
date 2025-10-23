{ helix-fork, pkgs, ... }:
{
  programs.helix = {
    enable = true;
    package = helix-fork.packages.${pkgs.system}.default;
    extraPackages = with pkgs; [
      nixpkgs-fmt
    ];
    defaultEditor = true;
    settings = {
      theme = "flexoki_dark";
      editor = {
        line-number = "relative";
        mouse = true;
        auto-info = true;
        true-color = true;
        color-modes = true;
        rulers = [ 120 ];
        text-width = 120;
        popup-border = "all";
        completion-replace = true;
        continue-comments = false;
        bufferline.render-mode = "multiple";
        rainbow-brackets = true;

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
        whitespace.render = {
          tab = "none";
          space = "none";
          newline = "none";
        };

        whitespace.characters = {
          space = "·";
          nbsp = "⍽";
          tab = "→";
          newline = "⏎";
          tabpad = "·";
        };

        statusline = {
          left = [ "mode" "spinner" ];
          center = [ "file-name" "file-modification-indicator" ];
          right = [ "version-control" "diagnostics" "selections" "position" "file-encoding" "file-line-ending" "file-type" "total-line-numbers" ];
        };

        inline-diagnostics = {
          cursor-line = "hint";
          other-lines = "error";
        };

        # Fork settings
        rounded-corners = true;
        # cmdline.style = "popup";
        gradient-borders = {
          enable = true;
          thickness = 2;
          direction = "horizontal";
          start-color = "#FF0080";
          end-color = "#00FFFF";
          animation-speed = 2;
        };
        inline-blame = {
          show = "cursor-line";
          format = "{commit} - {author} ({time-ago}): {title}";
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
          # Switch p and P behaviour
          # "P" = [ "paste_after" ];
          # "p" = [ "paste_before" ];
          "C-y" = [ ":sh zellij run -fc -x 10%% -y 10%% --width 80%% --height 80%% -- bash ~/.config/helix/yazi-picker.sh open %{buffer_name}" ];
        };

        normal.space.g = {
          "g" = [ ":sh zellij run -fc -x 10%% -y 10%% --width 80%% --height 80%% -- gitui" ];
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

        vscode-eslint-language-server = {
          config = {
            experimental = { useFlatConfig = true; };
            workingDirectory.mode = "auto";
            format.enable = false;
            codeActionsOnSave = { mode = "all"; "source.fixAll.eslint" = true; };
          };
        };

        typescript-language-server.config.javascript.inlayHints = {
          includeInlayEnumMemberValueHints = false;
          includeInlayFunctionLikeReturnTypeHints = false;
          includeInlayFunctionParameterTypeHints = false;
          includeInlayParameterNameHints = "all";
          includeInlayParameterNameHintsWhenArgumentMatchesName = false;
          includeInlayPropertyDeclarationTypeHints = false;
          includeInlayVariableTypeHints = false;
        };
        typescript-language-server.config.typescript.inlayHints = {
          includeInlayEnumMemberValueHints = false;
          includeInlayFunctionLikeReturnTypeHints = false;
          includeInlayFunctionParameterTypeHints = false;
          includeInlayParameterNameHints = "all";
          includeInlayParameterNameHintsWhenArgumentMatchesName = false;
          includeInlayPropertyDeclarationTypeHints = false;
          includeInlayVariableTypeHints = false;
        };

        biome = {
          command = "biome";
          args = [ "lsp-proxy" ];
        };

        gopls = {
          config = {
            "formatting.gofumpt" = true;
            # formatting = {
            #   gofumpt = true;
            # };
          };
        };

        roslyn-ls = {
          command = "Microsoft.CodeAnalysis.LanguageServer";
          args = [
            "--logLevel"
            "Information"
            "--extensionLogDirectory"
            "/tmp/roslyn_ls/logs"
            "--stdio"
          ];
        };

        csls = {
          command = "csharp-language-server";
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
          language-servers = [
            {
              except-features = [ "format" ];
              name = "typescript-language-server";
            }
            # "vscode-eslint-language-server"
            "biome"
            "tailwindcss-ls"
          ];
          # formatter = { command = "prettier"; args = [ "--parser" "typescript" ]; };
        }
        {
          name = "tsx";
          indent = { tab-width = 4; unit = "    "; };
          auto-format = true;
          language-servers = [
            {
              except-features = [ "format" ];
              name = "typescript-language-server";
            }
            # "vscode-eslint-language-server"
            "biome"
            "tailwindcss-ls"
          ];
          # formatter = { command = "prettier"; args = [ "--parser" "typescript" ]; };
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
          formatter = { command = "yamlfmt"; args = [ "-formatter" "indent=4,retain_line_breaks_single=true" "-" ]; };
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
          language-servers = [ "ruff" "basedpyright" ];
        }
        {
          name = "nix";
          indent = { tab-width = 2; unit = "  "; };
          auto-format = true;
          formatter = { command = "nixpkgs-fmt"; };
        }
        {
          name = "c-sharp";
          indent = { tab-width = 4; unit = "  "; };
          auto-format = true;
          language-servers = [
            # "omnisharp"
            # "csharp-ls"
            "roslyn-ls"
            "csls"
          ];
        }
      ];
    };
  };

  home.file.".config/helix/themes/carbon.toml".source = ./configs/helix/carbon.toml;
  home.file.".config/helix/themes/nosferatu.toml".source = ./configs/helix/nosferatu.toml;
  home.file.".config/helix/themes/paper-nord.toml".source = ./configs/helix/paper-nord.toml;
  home.file.".config/helix/themes/adwaita-light-inlay.toml".source = ./configs/helix/adwaita-light-inlay.toml;
  home.file.".config/helix/themes/oceanic-next.toml".source = ./configs/helix/oceanic-next.toml;
  home.file.".config/helix/themes/panda.toml".source = ./configs/helix/panda.toml;
  home.file.".config/helix/yazi-picker.sh".source = ./configs/helix/yazi-picker.sh;

}

