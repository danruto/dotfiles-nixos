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
        plugins = with pkgs.vimPlugins; [
          nvim-ts-autotag
          editorconfig-nvim
          vim-closetag
          tagalong-vim
          nvim-treesitter
          nvim-treesitter-context
          nvim-treesitter-textobjects
          nvim-treesitter-textsubjects
          nvim-treesitter-endwise
          flash-nvim
          # { name = "mini.ai"; path = mini-nvim; }
          { name = "mini.bracketed"; path = mini-nvim; }
          { name = "mini.bufremove"; path = mini-nvim; }
          { name = "mini.comment"; path = mini-nvim; }
          { name = "mini.cursorword"; path = mini-nvim; }
          { name = "mini.doc"; path = mini-nvim; }
          { name = "mini.hues"; path = mini-nvim; }
          { name = "mini.indentscope"; path = mini-nvim; }
          { name = "mini.pairs"; path = mini-nvim; }
          { name = "mini.splitjoin"; path = mini-nvim; }
          { name = "mini.surround"; path = mini-nvim; }
          # { name = "mini.statusbar"; path = mini-nvim; }
          { name = "mini.trailspace"; path = mini-nvim; }
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
          # lsp-lens
          friendly-snippets
          { name = "LuaSnip"; path = luasnip; }
          impatient-nvim
          nvim-web-devicons
          nvim-notify
          dressing-nvim
          Shade-nvim
          # expressline
          #icon-picker.nvim
          nvim-colorizer-lua
          true-zen-nvim
          winshift-nvim
          #floate
          trouble-nvim
          telescope-nvim
          neo-tree-nvim
          # github-nvim-theme
          neovim-ayu
          # bloop
          papercolor-theme
          # snowy
          # ohlucy
          # moonbow
          # danger
          # nvim-colo
          tokyonight-nvim
          # nightly
          nordic-nvim







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
# barbecue, bloop.nvim, editorconfig-vim, express_line.nvim, floate.nvim, github-nvim-theme, icon-picker.nvim, lsp-lens.nvim, lsp_lines.nvim, lspkind.nvim, lush.nvim, mini.nvim, moonbow.nvim, nightly.nvim, nvim-colo, nvim-tresitter-refactor, oh-lucy, snowy0vim
