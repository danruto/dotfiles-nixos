{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    # package = pkgs.unstable.neovim;
    extraPackages = with pkgs; [
      # LazyVim
      # lua-language-server
      # stylua
      # gopls
      # rust-analyzer
      # nodePackages.typescript-language-server

      # Telescope
      ripgrep
      nixpkgs-fmt
    ];

    plugins = with pkgs.vimPlugins; [
      lazy-nvim
    ];

    # https://github.com/seppeljordan/nix-prefetch-github
    extraLuaConfig =
      let
        tailwindcss-colorizer-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "tailwindcss-colorizer-cmp.nvim";
          version = "2024-02-01";
          src = pkgs.fetchFromGitHub {
            owner = "roobert";
            repo = "tailwindcss-colorizer-cmp.nvim";
            rev = "bc25c56083939f274edcfe395c6ff7de23b67c50";
            hash = "sha256-4wt4J6pENX7QRG7N1GzE9L6pM5E88tnHbv4NQa5JqSI=";
          };
        };
        venv-selector-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "venv-selector.nvim";
          version = "2024-02-01";
          src = pkgs.fetchFromGitHub {
            owner = "linux-cultist";
            repo = "venv-selector.nvim";
            rev = "fcb30164f2c4f8a34a305ead3247954a1fd8634f";
            hash = "sha256-wtE63f6gNq0hNRILYR40w3undahAqGoQcXsP3f/8usY";
          };
        };
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
          pname = "danger-vim";
          version = "2024-02-01";
          src = pkgs.fetchFromGitHub {
            owner = "igorgue";
            repo = "danger";
            rev = "01482cd1dd80fc1709994ea0c3571bead8a6a1bc";
            hash = "sha256-Vfb+lOqLAt7dxt6y25RVid5qxTr8iZtqT3aZ2izAkIQ=";
          };
        };
        darkrose-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "darkrose-nvim";
          version = "2024-02-01";
          src = pkgs.fetchFromGitHub {
            owner = "water-sucks";
            repo = "darkrose.nvim";
            rev = "4b39e4e6c86f9d8e61c107ee685c55da55e04931";
            hash = "sha256-aXCu71Yu397a91yVjHh4XQgJblqh0XKgifYCn9Lr7mM=";
          };
        };
        abyss-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "abyss-nvim";
          version = "2024-02-01";
          src = pkgs.fetchFromGitHub {
            owner = "barrientosvctor";
            repo = "abyss.nvim";
            rev = "b486ca9a53fa2d0189bbe45828a328bc438eeb57";
            hash = "sha256-bq1SkY8Kb6GD+l1wuk0BAqlb8AUFqor5mMV4GJJ+gVg=";
          };
        };
        plugins = with pkgs.vimPlugins;
          [
            # LazyVim
            LazyVim
            cmp-buffer
            cmp-nvim-lsp
            cmp-path
            cmp_luasnip
            conform-nvim
            dashboard-nvim
            dressing-nvim
            flash-nvim
            friendly-snippets
            gitsigns-nvim
            indent-blankline-nvim
            lualine-nvim
            neo-tree-nvim
            neoconf-nvim
            neodev-nvim
            noice-nvim
            nui-nvim
            nvim-cmp
            nvim-lint
            nvim-lspconfig
            nvim-notify
            nvim-spectre
            nvim-treesitter
            nvim-treesitter-context
            nvim-treesitter-textobjects
            nvim-ts-autotag
            nvim-ts-context-commentstring
            nvim-web-devicons
            plenary-nvim
            telescope-fzf-native-nvim
            telescope-nvim
            todo-comments-nvim
            tokyonight-nvim
            trouble-nvim
            vim-illuminate
            vim-startuptime
            which-key-nvim
            {
              name = "LuaSnip";
              path = luasnip;
            }
            {
              name = "catppuccin";
              path = catppuccin-nvim;
            }
            {
              name = "mini.ai";
              path = mini-nvim;
            }
            {
              name = "mini.bracketed";
              path = mini-nvim;
            }
            {
              name = "mini.bufremove";
              path = mini-nvim;
            }
            {
              name = "mini.comment";
              path = mini-nvim;
            }
            {
              name = "mini.indentscope";
              path = mini-nvim;
            }
            {
              name = "mini.pairs";
              path = mini-nvim;
            }
            {
              name = "mini.surround";
              path = mini-nvim;
            }
            {
              name = "mini.trailspace";
              path = mini-nvim;
            }
            crates-nvim
            nvim-navic
            rust-tools-nvim
            typescript-nvim
            tailwindcss-colorizer-nvim
            venv-selector-nvim
            neovim-ayu
            papercolor-theme
            snowy-vim
            danger-vim
            kanagawa-nvim
            darkrose-nvim
            abyss-nvim
          ];
        mkEntryFromDrv = drv:
          if lib.isDerivation drv then
            { name = "${lib.getName drv}"; path = drv; }
          else
            drv;
        lazyPath = pkgs.linkFarm "lazy-plugins" (builtins.map mkEntryFromDrv plugins);
      in
      ''
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
            { "LazyVim/LazyVim", import = "lazyvim.plugins" },
            -- The following configs are needed for fixing lazyvim on nix
            -- force enable telescope-fzf-native.nvim
            { "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
            -- disable mason.nvim, use programs.neovim.extraPackages
            { "williamboman/mason-lspconfig.nvim", enabled = false },
            { "williamboman/mason.nvim", enabled = false },
            -- import/override with your plugins
            { import = "plugins" },
            -- treesitter handled by xdg.configFile."nvim/parser", put this line at the end of spec to clear ensure_installed
            { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {} } },
            -- disable bufferline because I don't like it
            { "akinsho/bufferline.nvim", enabled = false },
            -- I hate it jumping around with incorrect context
            { "folke/persistence.nvim", enabled = false },
          },
        	performance = {
        		rtp = {
        			disabled_plugins = {
        				"2html_plugin",
        				"getscript",
        				"getscriptPlugin",
        				"gzip",
        				"logipat",
        				"netrw",
        				"netrwPlugin",
        				"netrwSettings",
        				"netrwFileHandlers",
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
        paths = (pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
          bash
          c
          cpp
          css
          fish
          gitignore
          go
          graphql
          html
          http
          javascript
          json
          jsonc
          lua
          markdown
          nix
          python
          regex
          rust
          scss
          sql
          toml
          tsx
          typescript
          vim
          yaml
        ])).dependencies;
      };
    in
    "${parsers}/parser";

  # Normal LazyVim config here, see https://github.com/LazyVim/starter/tree/main/lua
  xdg.configFile."nvim/lua".source = ./configs/lazyvim;
}
