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
      mermaid-cli
      imagemagick
    ];

    extraLuaPackages = ps: [ ps.magick ];

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
          version = "2025-04-16";
          src = pkgs.fetchFromGitHub {
            owner = "igorgue";
            repo = "danger";
            rev = "5258fe08ce490184d5fdefb51bc2c6c3c48ced1c";
            hash = "sha256-EytucoisMWnQvPymiUepjq62TZ7QtcE+lHxNqLy63xU=";
          };
        };

        github-nvim-theme = pkgs.vimUtils.buildVimPlugin {
          pname = "github-nvim-theme";
          version = "2025-04-16";
          src = pkgs.fetchFromGitHub {
            owner = "projekt0n";
            repo = "github-nvim-theme";
            rev = "c106c9472154d6b2c74b74565616b877ae8ed31d";
            hash = "sha256-/A4hkKTzjzeoR1SuwwklraAyI8oMkhxrwBBV9xb59PA=";
          };
        };

        ohlucy-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "oh-lucy.nvim";
          version = "2025-04-16";
          src = pkgs.fetchFromGitHub {
            owner = "Yazeed1s";
            repo = "oh-lucy.nvim";
            rev = "2d94e9b03efe4c50f4653b6f2b7b200d970fe1aa";
            hash = "sha256-tH44CJnx/ZVwD+U9V7gDVjAjGCQtcnKDxVnVd+vkLz0=";
          };
        };

        cuddlefish-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "cuddlefish.nvim";
          version = "2025-04-16";
          src = pkgs.fetchFromGitHub {
            owner = "comfysage";
            repo = "cuddlefish.nvim";
            rev = "0cb027aabbc1067d599209e9342bab067962874d";
            hash = "sha256-zzKmnD3fpVgSPOrYUfoDth5vPtlfXL3gvv0F2gkjIS8=";
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
          version = "2025-04-16";
          src = pkgs.fetchFromGitHub {
            owner = "diegoulloao";
            repo = "neofusion.nvim";
            rev = "e705c8dc7ce2f50b813479400cd9a8724425a211";
            hash = "sha256-gZQ2SIxnb2xc/6lzgb3IBxTBGBYG8+qdw1DjCoxSJ/I=";
          };
        };

        render-markdown-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "render-markdown.nvim";
          version = "2025-02-09";
          src = pkgs.fetchFromGitHub {
            owner = "MeanderingProgrammer";
            repo = "render-markdown.nvim";
            rev = "a2c2493c21cf61e5554ee8bc83da75bd695921da";
            hash = "sha256-v66YkFT1L/4xsDK3C/0BHsvtxsGhuC7qUxJCKjIrEM0=";
          };
        };

        neocodeium = pkgs.vimUtils.buildVimPlugin {
          pname = "neocodeium";
          version = "2025-04-16";
          src = pkgs.fetchFromGitHub {
            owner = "monkoose";
            repo = "neocodeium";
            rev = "1404685e72030d974f13d932fe4830ecc8a43f04";
            hash = "sha256-+FK12qDw7EkUXjKwfAdvR1yzD/gVt+fZSWP1Ckjq+Wo=";
          };
        };

        makurai-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "makurai-nvim";
          version = "2025-04-16";
          src = pkgs.fetchFromGitHub {
            owner = "Skardyy";
            repo = "makurai-nvim";
            rev = "50a9a966c41dad5cc9818c35a87cc124bddee2c1";
            hash = "sha256-hClIMHmRH++8NP+oL9iDBNSUuIOjAZPDBodtEPxWsWY=";
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
          snacks-nvim
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
          # lsp-inlayhints-nvim
          lsp-lens-nvim
          tiny-inline-diagnostic-nvim
          nui-nvim
          nvim-web-devicons
          todo-comments-nvim
          dropbar-nvim
          nvim-colorizer-lua
          diagram-nvim
          image-nvim
          render-markdown-nvim

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
          # avante-nvim
          # codecompanion-nvim

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
          cuddlefish-nvim
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

