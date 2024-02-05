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
          cmp-buffer
          cmp-nvim-lsp
          cmp-path
          cmp_luasnip
          dressing-nvim
          flash-nvim
          friendly-snippets
          gitsigns-nvim
          indent-blankline-nvim
          neo-tree-nvim
          noice-nvim
          nui-nvim
          nvim-cmp
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
          { name = "LuaSnip"; path = luasnip; }
          { name = "catppuccin"; path = catppuccin-nvim; }
          { name = "mini.ai"; path = mini-nvim; }
          { name = "mini.bracketed"; path = mini-nvim; }
          { name = "mini.bufremove"; path = mini-nvim; }
          { name = "mini.comment"; path = mini-nvim; }
          { name = "mini.indentscope"; path = mini-nvim; }
          { name = "mini.pairs"; path = mini-nvim; }
          { name = "mini.surround"; path = mini-nvim; }
          { name = "mini.trailspace"; path = mini-nvim; }
          crates-nvim
          nvim-navic
          rust-tools-nvim
          typescript-nvim
          tailwindcss-colorizer-nvim
          neovim-ayu
          papercolor-theme
          editorconfig-nvim
          vim-closetag
          tagalong-vim
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
            { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {} } },
            { "williamboman/mason-lspconfig.nvim", enabled = false },
            { "williamboman/mason.nvim", enabled = false },
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
  xdg.configFile."nvim/lua".source = ./configs/nvim;
}
