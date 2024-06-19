{ lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    package = pkgs.unstable.neovim-unwrapped;
    # package = pkgs.neovim-unwrapped;
    # package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
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
          version = "2024-06-19";
          src = pkgs.fetchFromGitHub {
            owner = "igorgue";
            repo = "danger";
            rev = "a1ac47deb21ec2c4aff1c64b72dbfd151514fefc";
            hash = "sha256-oWkXs9y7O8rUbE7lqhjJH2Z9Kx0BJgF36FFmWdDfRqo=";
          };
        };
        github-nvim-theme = pkgs.vimUtils.buildVimPlugin {
          pname = "github-nvim-theme";
          version = "2024-06-19";
          src = pkgs.fetchFromGitHub {
            owner = "projekt0n";
            repo = "github-nvim-theme";
            rev = "d832925e77cef27b16011a8dfd8835f49bdcd055";
            hash = "sha256-vsIr3UrnajxixDo0cp+6GoQfmO0KDkPX8jw1e0fPHo4=";
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

        pineapple-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "pineapple";
          version = "2024-02-23";
          src = pkgs.fetchFromGitHub {
            owner = "CWood-sdf";
            repo = "pineapple";
            rev = "2ddd76ec9fdc68b514c9ec45412c3b48a97b0ef4";
            hash = "sha256-d3+lhm4Sq4FIQVSBPrqQJQBdvkphZ10OS4ObUD04UkI=";
          };
        };

        nvim-nio = pkgs.vimUtils.buildVimPlugin {
          pname = "nvim-nio";
          version = "2024-06-19";
          src = pkgs.fetchFromGitHub {
            owner = "nvim-neotest";
            repo = "nvim-nio";
            rev = "7969e0a8ffabdf210edd7978ec954a47a737bbcc";
            hash = "sha256-gAbqGPNBYkj+x+wR6WN2x7kqKaxlBzVXPmRXm8sM40Y=";
          };
        };

        monet-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "monet.nvim";
          version = "2024-06-19";
          src = pkgs.fetchFromGitHub {
            owner = "fynnfluegge";
            repo = "monet.nvim";
            rev = "e358f6b0035932c6faad8cd4157e4dd2272f88a2";
            hash = "sha256-qquos+vbYGsLeY/yAd9lUj6usuWgx0/u4JFO4q7vgJc=";
          };
        };

        neofusion-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "neofusion.nvim";
          version = "2024-06-19";
          src = pkgs.fetchFromGitHub {
            owner = "diegoulloao";
            repo = "neofusion.nvim";
            rev = "d6c861b230ad67341db6916892939cf3c54a18f8";
            hash = "sha256-FiwzQOXvUosLSN4HXdSxCOaSDVaWHDzhWh3x7EeXURY=";
          };
        };

        plugins = with pkgs.unstable.vimPlugins; [
          nvim-ts-autotag
          editorconfig-vim
          vim-closetag
          tagalong-vim
          nvim-treesitter
          nvim-treesitter-context
          nvim-treesitter-textobjects
          nvim-treesitter-textsubjects
          nvim-treesitter-endwise
          nvim-treesitter-refactor
          nvim-ts-context-commentstring
          flash-nvim
          mini-nvim
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
          plenary-nvim
          diffview-nvim
          gitsigns-nvim
          neogit
          nvim-lspconfig
          # nvim-navbuddy
          # nvim-navic
          # barbecue-nvim
          nui-nvim
          # copilot-lua
          crates-nvim
          nvim-cmp
          cmp-buffer
          cmp-nvim-lsp
          { name = "lspkind.nvim"; path = lspkind-nvim; }
          cmp-nvim-lsp-signature-help
          cmp-path
          cmp-nvim-lua
          cmp_luasnip
          cmp-under-comparator
          cmp-cmdline
          cmp-nvim-lsp-document-symbol
          # copilot-cmp
          # none-ls-nvim
          conform-nvim
          typescript-tools-nvim
          # rust-tools-nvim
          rustaceanvim
          nvim-dap
          nvim-dap-ui
          nvim-nio
          hover-nvim
          lsp-inlayhints-nvim
          # fidget-nvim
          lsp-lens-nvim
          friendly-snippets
          { name = "LuaSnip"; path = luasnip; }
          impatient-nvim
          nvim-web-devicons
          nvim-notify
          dressing-nvim
          { name = "shade.nvim"; path = Shade-nvim; }
          # expressline
          icon-picker-nvim
          nvim-colorizer-lua
          true-zen-nvim
          winshift-nvim
          trouble-nvim
          telescope-nvim
          neo-tree-nvim
          github-nvim-theme
          neovim-ayu
          papercolor-theme
          snowy-vim
          ohlucy-nvim
          # moonbow
          danger-vim
          # nvim-colo
          tokyonight-nvim
          # nightly
          nordic-nvim
          lazy-lsp-nvim
          lsp_lines-nvim
          nvim-spectre
          todo-comments-nvim
          pineapple-nvim
          codeium-nvim
          dropbar-nvim
          telescope-fzf-native-nvim
          { name = "catppuccin"; path = catppuccin-nvim; }
          monet-nvim
          neofusion-nvim







          # Lazy plugins we can check out later
          # noice-nvim
          # telescope-fzf-native-nvim
          # vim-illuminate
          # vim-startuptime
          # typescript-nvim
          # tailwindcss-colorizer-nvim
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
        paths = (pkgs.unstable.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
          bash
          c
          cpp
          css
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

  xdg.configFile."nvim/after".source = ./configs/nvim/after;
  xdg.configFile."nvim/lua".source = ./configs/nvim/lua;
}

# TODO: Port to nix:
# barbecue, lsp_lines.nvim, lspkind.nvim, moonbow.nvim, nightly.nvim, nvim-colo
