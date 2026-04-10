{ lib, pkgs, pkgs-unstable, neovim-nightly-overlay, fff, ... }:

{
  programs.neovim = {
    enable = true;
    # package = pkgs.neovim-unwrapped;
    # package = pkgs.unstable.neovim-unwrapped.override ({ tree-sitter = pkgs.tree-sitter; });
    # package = pkgs.unstable.neovim-unwrapped;
    package = neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;

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
          version = "2025-12-27";
          src = pkgs.fetchFromGitHub {
            owner = "igorgue";
            repo = "danger";
            rev = "7811b863c7012b3937793973200130f8964415f3";
            hash = "sha256-SnQfJzp00L+VuWr2K0+nMT0/u8HBOgyVnKk22wBrjHs=";
          };
        };

        ohlucy-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "oh-lucy.nvim";
          version = "2025-04-08";
          src = pkgs.fetchFromGitHub {
            owner = "Yazeed1s";
            repo = "oh-lucy.nvim";
            rev = "2d94e9b03efe4c50f4653b6f2b7b200d970fe1aa";
            hash = "sha256-tH44CJnx/ZVwD+U9V7gDVjAjGCQtcnKDxVnVd+vkLz0=";
          };
        };

        # cuddlefish-nvim = pkgs.vimUtils.buildVimPlugin {
        #   pname = "cuddlefish.nvim";
        #   version = "2025-05-24";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "comfysage";
        #     repo = "cuddlefish.nvim";
        #     rev = "6448a5f44628dbf8677d72bd3e9ad6e89bd6a7d8";
        #     hash = "sha256-ZZ5kE/MikATxbtmhoXYvkxRaIgseCDAkfZse4NaWoes=";
        #   };
        # };

        monet-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "monet.nvim";
          version = "2025-12-27";
          src = pkgs.fetchFromGitHub {
            owner = "fynnfluegge";
            repo = "monet.nvim";
            rev = "8fba02c535a408d5e5255251665325a69fa12a8e";
            hash = "sha256-fUnwv0mppD+sqlWMgbR/f/75Bau7psoSpiUVCQ/DxH4=";
          };
        };

        neofusion-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "neofusion.nvim";
          version = "2025-03-17";
          src = pkgs.fetchFromGitHub {
            owner = "diegoulloao";
            repo = "neofusion.nvim";
            rev = "e705c8dc7ce2f50b813479400cd9a8724425a211";
            hash = "sha256-gZQ2SIxnb2xc/6lzgb3IBxTBGBYG8+qdw1DjCoxSJ/I=";
          };
        };

        # neocodeium = pkgs.vimUtils.buildVimPlugin {
        #   pname = "neocodeium";
        #   version = "2025-06-11";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "monkoose";
        #     repo = "neocodeium";
        #   };
        # };

        makurai-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "makurai-nvim";
          version = "2025-12-27";
          src = pkgs.fetchFromGitHub {
            owner = "Skardyy";
            repo = "makurai-nvim";
            rev = "f421ded3c242f1d89249577856f18546412a4e1b";
            hash = "sha256-y6LKtL/HaVGc2tjZIrPwV4D7nyHmqs/gDaRVPl1UAoc=";
          };
        };

        gopher-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "gopher.nvim";
          version = "2025-12-27";
          src = pkgs.fetchFromGitHub {
            owner = "olexsmir";
            repo = "gopher.nvim";
            rev = "6a3924cee5a9f36d316f8e4a90c3020438d3513f";
            hash = "sha256-iXTmgdADtZFQVm+IN+JoPActGuO8r7VTeHKJdkEgmVo=";
          };
        };

        # mssql-nvim = pkgs.vimUtils.buildVimPlugin {
        #   pname = "mssql.nvim";
        #   version = "2025-05-28";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "Kurren123";
        #     repo = "mssql.nvim";
        #     rev = "551edd9572cbe50574dacac6287faeea59c25a78";
        #     hash = "sha256-/Bk9MMVol8bPPsVnn5Dtfz3cj4CPqkObFu1kulld548=";
        #   };
        # };

        debugmaster-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "debugmaster.nvim";
          version = "2026-01-02";
          src = pkgs.fetchFromGitHub {
            owner = "miroshQa";
            repo = "debugmaster.nvim";
            rev = "505d9a269d657ce8e0fa5601e0530f0d8798038c";
            hash = "sha256-xA0zFVgtZLsxX3gyfbLnitfNwdsn+p29euIJtnEaPv8=";
          };
          doCheck = false;
        };

        # lazy-lsp-nvim = pkgs.vimUtils.buildVimPlugin {
        #   pname = "lazy-lsp.nvim";
        #   version = "2025-10-15";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "dundalek";
        #     repo = "lazy-lsp.nvim";
        #     rev = "d74741ce1a588fe11900b5bcd5cd160b04998f60";
        #     hash = "sha256-5oiiOYMd8I00ItQsJCphbNtXzW5NgsIn4IDKGmlOues=";
        #   };
        #   doCheck = false;
        # };

        plugins = with pkgs.vimPlugins; [
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
          grug-far-nvim
          fff.packages.${pkgs.stdenv.hostPlatform.system}.fff-nvim

          # UI
          # lsp-inlayhints-nvim
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
          (pkgs-unstable.vimPlugins.nvim-treesitter)
          (pkgs-unstable.vimPlugins.nvim-treesitter-context)
          (pkgs-unstable.vimPlugins.nvim-treesitter-textobjects)
          (pkgs-unstable.vimPlugins.nvim-treesitter-endwise)
          (pkgs-unstable.vimPlugins.nvim-ts-context-commentstring)
          nvim-lspconfig
          blink-cmp
          lazy-lsp-nvim
          nvim-dap
          # nvim-dap-ui
          debugmaster-nvim
          nvim-dap-go
          nvim-nio
          # neotest
          roslyn-nvim
          gopher-nvim

          # LLM
          # neocodeium
          # codecompanion-nvim
          avante-nvim
          blink-cmp-avante

          # Snippets
          friendly-snippets
          { name = "LuaSnip"; path = luasnip; }

          # UI Utils
          # mssql-nvim
          nvim-dbee

          # Formatters
          editorconfig-vim
          conform-nvim

          # Treesitter grammars (use pkgs-unstable to match nvim-treesitter queries)
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.bash
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.c
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.c_sharp
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.cpp
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.css
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.dockerfile
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.fish
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.gitignore
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.gleam
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.go
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.graphql
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.html
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.http
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.hurl
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.javascript
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.json
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.json5
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.just
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.lua
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.markdown
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.nix
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.python
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.regex
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.rust
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.scss
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.sql
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.svelte
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.toml
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.tsx
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.typescript
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.vim
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.yaml
          pkgs-unstable.vimPlugins.nvim-treesitter-parsers.zig

          # Themes
          github-nvim-theme
          neovim-ayu
          # papercolor-theme
          papercolor-theme-slim
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
          # cuddlefish-nvim
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
          rocks = {
            enabled = false,
          },
          dev = {
            -- reuse files from pkgs.vimPlugins.*
            path = "${lazyPath}",
            patterns = { "." },
            -- fallback to download
            fallback = true,
          },
          spec = {
            { "nvim-treesitter/nvim-treesitter" },
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

  xdg.configFile."nvim/parser".source =
    let
      parsers = pkgs.symlinkJoin {
        name = "treesitter-parsers";
        paths = with pkgs-unstable.vimPlugins; [
          nvim-treesitter-parsers.bash
          nvim-treesitter-parsers.c
          nvim-treesitter-parsers.c_sharp
          nvim-treesitter-parsers.cpp
          nvim-treesitter-parsers.css
          nvim-treesitter-parsers.dockerfile
          nvim-treesitter-parsers.fish
          nvim-treesitter-parsers.gitignore
          nvim-treesitter-parsers.gleam
          nvim-treesitter-parsers.go
          nvim-treesitter-parsers.graphql
          nvim-treesitter-parsers.html
          nvim-treesitter-parsers.http
          nvim-treesitter-parsers.hurl
          nvim-treesitter-parsers.javascript
          nvim-treesitter-parsers.json
          nvim-treesitter-parsers.json5
          nvim-treesitter-parsers.just
          nvim-treesitter-parsers.lua
          nvim-treesitter-parsers.markdown
          nvim-treesitter-parsers.nix
          nvim-treesitter-parsers.python
          nvim-treesitter-parsers.regex
          nvim-treesitter-parsers.rust
          nvim-treesitter-parsers.scss
          nvim-treesitter-parsers.sql
          nvim-treesitter-parsers.svelte
          nvim-treesitter-parsers.toml
          nvim-treesitter-parsers.tsx
          nvim-treesitter-parsers.typescript
          nvim-treesitter-parsers.vim
          nvim-treesitter-parsers.yaml
          nvim-treesitter-parsers.zig
        ];
      };
    in
    "${parsers}/parser";

  xdg.configFile."nvim/after".source = ./configs/nvim/after;
  xdg.configFile."nvim/lua".source = ./configs/nvim/lua;

}

