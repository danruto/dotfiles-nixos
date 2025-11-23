{ lib, pkgs, pkgs-unstable, neovim-nightly-overlay, ... }:

{
  programs.neovim = {
    enable = true;
    # package = pkgs.neovim-unwrapped;
    # package = pkgs.unstable.neovim-unwrapped.override ({ tree-sitter = pkgs.tree-sitter; });
    # package = pkgs.unstable.neovim-unwrapped;
    package = neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      meta = old.meta or { } // {
        maintainers = [ ];
      };
    });

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
          version = "2025-10-18";
          src = pkgs.fetchFromGitHub {
            owner = "igorgue";
            repo = "danger";
            rev = "e5582e086b263320730f05d72aa713544c7b1aee";
            hash = "sha256-s7ExeSRZI4w84QB0PxLklo6DptXIPHYebovHD4YUQlI=";
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
          version = "2025-08-11";
          src = pkgs.fetchFromGitHub {
            owner = "fynnfluegge";
            repo = "monet.nvim";
            rev = "f0db469c38ddcb9c12a44662a00d65e9894a5a34";
            hash = "sha256-3Km/3QGhUGSi6Cg2lEvTOUTZwvuSt0WAvsVhXtMysho=";
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
          version = "2025-09-25";
          src = pkgs.fetchFromGitHub {
            owner = "Skardyy";
            repo = "makurai-nvim";
            rev = "a12c94cd9a90186189ba4434021a2deb27cfea39";
            hash = "sha256-gNxnYpsT8Z/uruCPOzJ/RrGgjxIQYSrCFqZ2DH7KDZw=";
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
          version = "2025-08-07";
          src = pkgs.fetchFromGitHub {
            owner = "miroshQa";
            repo = "debugmaster.nvim";
            rev = "3d144b98c2c23f39123fbf5f10fdff7d6480a0e6";
            hash = "sha256-pdgS0z8KdLsl7VexbPaRPtYc2lebzAgTtM3B52IaCpQ=";
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

        plugins = with pkgs-unstable.vimPlugins; [
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
          debugmaster-nvim
          nvim-dap-go
          nvim-nio
          # neotest
          roslyn-nvim

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
        paths = (pkgs-unstable.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
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

