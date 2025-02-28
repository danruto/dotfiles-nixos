{ lib, pkgs, neovim-nightly-overlay, ... }:

{
  programs.neovim = {
    enable = true;
    # package = pkgs.neovim-unwrapped;
    # package = pkgs.unstable.neovim-unwrapped.override ({ tree-sitter = pkgs.tree-sitter; });
    # package = pkgs.unstable.neovim-unwrapped;
    package = neovim-nightly-overlay.packages.${pkgs.system}.default;

    extraPackages = with pkgs; [
      # Telescope
      ripgrep
      nixpkgs-fmt
      stylua
    ];

    plugins = with pkgs.vimPlugins; [
      lazy-nvim
    ];

    extraLuaConfig =
      let
        snowy-vim = pkgs.vimUtils.buildVimPlugin {
          pname = "snowy-vim";
          version = "2024-02-01";
          src = pkgs.fetchFromGitHub {
            owner = "yuttie";
            repo = "snowy-vim";
            rev = "2324e8a956baba46d0ab3ea2d823046e4a54e0af";
            hash = "sha256-kiV+J0kCbgaTUMjEht9G1aZFl5TtoTP8TvtXTQRHDq8=";
          };
        };

        danger-vim = pkgs.vimUtils.buildVimPlugin {
          pname = "danger";
          version = "2024-09-30";
          src = pkgs.fetchFromGitHub {
            owner = "igorgue";
            repo = "danger";
            rev = "804af61ada7da78e5c948abbdc04dd4e81a8a55b";
            hash = "sha256-fNvC0YkmSWej7m/it2j9MmZsC7eMQEzZQE4HQpbYqWg=";
          };
        };

        github-nvim-theme = pkgs.vimUtils.buildVimPlugin {
          pname = "github-nvim-theme";
          version = "2024-07-21";
          src = pkgs.fetchFromGitHub {
            owner = "projekt0n";
            repo = "github-nvim-theme";
            rev = "0e4636f556880d13c00d8a8f686fae8df7c9845f";
            hash = "sha256-EreIuni6/XR0428rO4Lbi2usIreOyPWKm7kJJA2Nwqo=";
          };
        };

        ohlucy-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "oh-lucy.nvim";
          version = "2024-06-19";
          src = pkgs.fetchFromGitHub {
            owner = "Yazeed1s";
            repo = "oh-lucy.nvim";
            rev = "05a0505f5288cd0ac905842eb54e63b45ebb3ec1";
            hash = "sha256-AgOA7otqdAu4ur1zkCw+aKS7Oi6j5XzdraKl9DKTUzs=";
          };
        };

        icon-picker-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "icon-picker.nvim";
          version = "2024-02-23";
          src = pkgs.fetchFromGitHub {
            owner = "ziontee113";
            repo = "icon-picker.nvim";
            rev = "3ee9a0ea9feeef08ae35e40c8be6a2fa2c20f2d3";
            hash = "sha256-VZKsVeSmPR3AA8267Mtd5sSTZl2CAqnbgqceCptgp4w=";
          };
        };

        lsp-lens-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "lsp-lens.nvim";
          version = "2024-02-23";
          src = pkgs.fetchFromGitHub {
            owner = "vidocqh";
            repo = "lsp-lens.nvim";
            rev = "48bb1a7e271424c15f3d588d54adc9b7c319d977";
            hash = "sha256-zj/Gn/40jnDNh05OFc23LNNuFn1PnIAUDfPquEWpAlk=";
          };
        };

        monet-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "monet.nvim";
          version = "2024-07-21";
          src = pkgs.fetchFromGitHub {
            owner = "fynnfluegge";
            repo = "monet.nvim";
            rev = "af6c8fb9faaae2fa7aa16dd83b1b425c2b372891";
            hash = "sha256-zNawnZRnyvn73viNN1R1jyvgiecT522/NQSZgJvzU9Q=";
          };
        };

        neofusion-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "neofusion.nvim";
          version = "2024-09-30";
          src = pkgs.fetchFromGitHub {
            owner = "diegoulloao";
            repo = "neofusion.nvim";
            rev = "f1776ed91ed7aa605d7827ee498b06bd8bbc37b5";
            hash = "sha256-FrWsYxaz3tkHhfuY7umASrH7yO2wf3JSTJNd6E/NUnk=";
          };
        };

        markdown-render-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "markdown.nvim";
          version = "2025-02-09";
          src = pkgs.fetchFromGitHub {
            owner = "MeanderingProgrammer";
            repo = "markdown.nvim";
            rev = "17a77463f945c4b9e4f371c752efd90e3e1bf604";
            hash = "sha256-x8FJNB30uhuwkieCcGdP7ct+DxbwlyOzaFFA6DRHwbE=";
          };
        };

        neocodeium = pkgs.vimUtils.buildVimPlugin {
          pname = "neocodeium";
          version = "2025-02-09";
          src = pkgs.fetchFromGitHub {
            owner = "monkoose";
            repo = "neocodeium";
            rev = "a2b5257c736886ec3ccbd961766f8ab9c82b2a72";
            hash = "sha256-mR2fzsdCVbh7nLcsSgQnhRivoKW6oFqJwuIYfz8OV0k=";
          };
        };

        my-snacks-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "snacks.nvim";
          version = "2025-02-27";
          src = pkgs.fetchFromGitHub {
            owner = "folke";
            repo = "snacks.nvim";
            rev = "1239fb84bc426d4fcd1c8dc9dde8503c17501842";
            hash = "sha256-7UbzP7d313TJ8/Ikk85n9Qd1JMwH0qEvEGML1P8cRpo=";
          };
        };

        makurai-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "makurai-nvim";
          version = "2025-02-13";
          src = pkgs.fetchFromGitHub {
            owner = "Skardyy";
            repo = "makurai-nvim";
            rev = "8fe07dd5d836b4dd5c6fbc8c48d604fe3a12b8b9";
            hash = "sha256-bZJU0cjtiY4l/9VhZRV70gV3U1xEZntlgiOXhnSYn04=";
          };
        };

        plugins = with pkgs.unstable.vimPlugins; [
          # Basic Deps
          plenary-nvim

          # QoL
          nvim-ts-autotag
          vim-closetag
          tagalong-vim
          typescript-tools-nvim
          crates-nvim
          rustaceanvim
          hover-nvim
          # snacks-nvim
          my-snacks-nvim
          mini-nvim
          # my-mini-nvim
          # { name = "mini.ai"; path = mini-nvim; }
          # { name = "mini.bracketed"; path = mini-nvim; }
          # { name = "mini.bufremove"; path = mini-nvim; }
          # { name = "mini.comment"; path = mini-nvim; }
          # { name = "mini.cursorword"; path = mini-nvim; }
          # { name = "mini.doc"; path = mini-nvim; }
          # { name = "mini.hues"; path = mini-nvim; }
          # { name = "mini.indentscope"; path = mini-nvim; }
          # { name = "mini.pairs"; path = mini-nvim; }
          # { name = "mini.splitjoin"; path = mini-nvim; }
          # { name = "mini.surround"; path = mini-nvim; }
          # { name = "mini.statusbar"; path = mini-nvim; }
          # { name = "mini.trailspace"; path = mini-nvim; }
          flash-nvim

          # UI
          lsp-inlayhints-nvim
          lsp-lens-nvim
          tiny-inline-diagnostic-nvim
          nui-nvim
          nvim-web-devicons
          todo-comments-nvim
          dropbar-nvim
          markdown-render-nvim
          nvim-colorizer-lua

          # Git
          diffview-nvim
          gitsigns-nvim
          neogit

          # LSP
          nvim-treesitter
          nvim-treesitter-context
          nvim-treesitter-textobjects
          nvim-treesitter-textsubjects
          nvim-treesitter-endwise
          nvim-treesitter-refactor
          nvim-ts-context-commentstring
          nvim-lspconfig
          blink-cmp
          lazy-lsp-nvim
          nvim-dap
          # nvim-dap-ui
          # nvim-nio
          # neotest

          # LLM
          neocodeium

          # Snippets
          friendly-snippets
          { name = "LuaSnip"; path = luasnip; }

          # Formatters
          editorconfig-vim
          conform-nvim

          # Themes
          github-nvim-theme
          neovim-ayu
          papercolor-theme
          snowy-vim
          ohlucy-nvim
          danger-vim
          tokyonight-nvim
          nordic-nvim
          { name = "catppuccin"; path = catppuccin-nvim; }
          monet-nvim
          neofusion-nvim
          oxocarbon-nvim
          makurai-nvim
        ];
        mkEntryFromDrv = drv:
          if lib.isDerivation drv then
            { name = "${lib.getName drv}"; path = drv; }
          else
            drv;
        lazyPath = pkgs.linkFarm "lazy-plugins" (builtins.map mkEntryFromDrv plugins);
      in
      ''

        require("dantoki")

        require("lazy").setup({
          defaults = {
            lazy = true,
          },
          dev = {
            -- reuse files from pkgs.vimPlugins.*
            path = "${lazyPath}",
            patterns = { "." },
            -- fallback to download
            fallback = true,
          },
          spec = {
            { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {} } },
            { "williamboman/mason-lspconfig.nvim", enabled = false },
            { "williamboman/mason.nvim", enabled = false },
            { import = "dantoki/plugins" },
          },
          performance = {
            rtp = {
              disabled_plugins = {
                "2html_plugin",
                "getscript",
                "getscriptPlugin",
                "gzip",
                "logipat",
                -- "netrw",
                -- "netrwPlugin",
                -- "netrwSettings",
                -- "netrwFileHandlers",
                "matchit",
                "tar",
                "tarPlugin",
                "rrhelper",
                "spellfile_plugin",
                "vimball",
                "vimballPlugin",
                "zip",
                "zipPlugin",
                "tutor",
                "rplugin",
                "syntax",
                "synmenu",
                "optwin",
                "compiler",
                "bugreport",
                "ftplugin",
              },
            },
          },
        })
      '';
  };

  # https://github.com/nvim-treesitter/nvim-treesitter#i-get-query-error-invalid-node-type-at-position
  xdg.configFile."nvim/parser".source =
    let
      parsers = pkgs.symlinkJoin {
        name = "treesitter-parsers";
        paths = (pkgs.unstable.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
          bash
          c
          cpp
          css
          dockerfile
          fish
          gitignore
          go
          graphql
          gleam
          html
          http
          javascript
          json
          jsonc
          json5
          just
          lua
          markdown
          nix
          python
          regex
          rust
          scss
          sql
          svelte
          toml
          tsx
          typescript
          vim
          yaml
          zig
        ])).dependencies;
      };
    in
    "${parsers}/parser";

  xdg.configFile."nvim/after".source = ./configs/nvim/after;
  xdg.configFile."nvim/lua".source = ./configs/nvim/lua;
}

