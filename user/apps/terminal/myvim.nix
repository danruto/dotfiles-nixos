{ lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    # package = pkgs.unstable.neovim;
    extraPackages = with pkgs; [
      # Telescope
      ripgrep
      nixpkgs-fmt
    ];

    plugins = with pkgs.vimPlugins; [
      lazy-nvim
    ];

    extraLuaConfig =
      let
        tailwindcss-colorizer-nvim = pkgs.vimUtils.buildVimPlugin {
          name = "tailwindcss-colorizer-cmp.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "roobert";
            repo = "tailwindcss-colorizer-cmp.nvim";
            rev = "bc25c56083939f274edcfe395c6ff7de23b67c50";
            hash = "sha256-4wt4J6pENX7QRG7N1GzE9L6pM5E88tnHbv4NQa5JqSI=";
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
        github-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "github-nvim";
          version = "2024-02-23";
          src = pkgs.fetchFromGitHub {
            owner = "projekt0n";
            repo = "github-nvim-theme";
            rev = "d92e1143e5aaa0d7df28a26dd8ee2102df2cadd8";
            hash = "sha256-FO4mwRY2qjutjVTiW0wN5KVhuoBZmycfOwMFInaTnNo=";
          };
        };
        ohlucy-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "ohlucy-nvim";
          version = "2024-02-23";
          src = pkgs.fetchFromGitHub {
            owner = "Yazeed1s";
            repo = "oh-lucy.nvim";
            rev = "b53f8c8735ca7e788994147bfa10eb04331eaf7c";
            hash = "sha256-5e+YlZD5DW8XXojhWyAE3NX4sxznTB4WyYajFQAZ4s8=";
          };
        };
        icon-picker-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "icon-picker-nvim";
          version = "2024-02-23";
          src = pkgs.fetchFromGitHub {
            owner = "ziontee113";
            repo = "icon-picker.nvim";
            rev = "3ee9a0ea9feeef08ae35e40c8be6a2fa2c20f2d3";
            hash = "sha256-VZKsVeSmPR3AA8267Mtd5sSTZl2CAqnbgqceCptgp4w";
          };
        };
        lsp-lens-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "lsp-lens-nvim";
          version = "2024-02-23";
          src = pkgs.fetchFromGitHub {
            owner = "vidocqh";
            repo = "lsp-lens.nvim";
            rev = "48bb1a7e271424c15f3d588d54adc9b7c319d977";
            hash = "sha256-zj/Gn/40jnDNh05OFc23LNNuFn1PnIAUDfPquEWpAlk=";
          };
        };


        plugins = with pkgs.vimPlugins; [
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
          flash-nvim
          mini-nvim
          # { name = "mini.ai"; path = mini-nvim; }
          # { name = "mini.bracketed"; path = mini-nvim; }
          # { name = "mini.bufremove"; path = mini-nvim; }
          # { name = "mini.comment"; path = mini-nvim; }
          # { name = "mini.cursorword"; path = mini-nvim; }
          # { name = "mini.doc"; path = mini-nvim; }
          { name = "mini.hues"; path = mini-nvim; }
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
          nvim-navbuddy
          nvim-navic
          nui-nvim
          copilot-lua
          crates-nvim
          nvim-cmp
          cmp-buffer
          cmp-nvim-lsp
          lspkind-nvim
          cmp-nvim-lsp-signature-help
          cmp-path
          cmp-nvim-lua
          cmp_luasnip
          cmp-under-comparator
          cmp-cmdline
          cmp-nvim-lsp-document-symbol
          copilot-cmp
          none-ls-nvim
          typescript-tools-nvim
          rust-tools-nvim
          nvim-dap
          nvim-dap-ui
          hover-nvim
          lsp-inlayhints-nvim
          fidget-nvim
          barbecue-nvim
          lsp-lens-nvim
          friendly-snippets
          { name = "LuaSnip"; path = luasnip; }
          impatient-nvim
          nvim-web-devicons
          nvim-notify
          dressing-nvim
          Shade-nvim
          # expressline
          icon-picker-nvim
          nvim-colorizer-lua
          true-zen-nvim
          winshift-nvim
          trouble-nvim
          telescope-nvim
          neo-tree-nvim
          github-nvim
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







          # Lazy plugins we can check out later
          # indent-blankline-nvim
          # noice-nvim
          # nvim-spectre
          # nvim-ts-context-commentstring
          # telescope-fzf-native-nvim
          # todo-comments-nvim
          # vim-illuminate
          # vim-startuptime
          # { name = "catppuccin"; path = catppuccin-nvim; }
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

        require("lazy-lsp").setup {}


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

  xdg.configFile."nvim/lua".source = ./configs/nvim/lua;
}

# TODO: Port to nix:
# barbecue, lsp_lines.nvim, lspkind.nvim, moonbow.nvim, nightly.nvim, nvim-colo
