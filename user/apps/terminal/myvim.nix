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
          version = "2024-07-21";
          src = pkgs.fetchFromGitHub {
            owner = "igorgue";
            repo = "danger";
            rev = "06b5b8fab49c2d541205a5dc7e94acac24025d63";
            hash = "sha256-8yR4r0OIbh6B5PbdCILzKwfOLSgID+g/yN/5EUEhag0=";
          };
        };

        github-nvim-theme = pkgs.vimUtils.buildVimPlugin {
          pname = "github-nvim-theme";
          version = "2024-07-21";
          src = pkgs.fetchFromGitHub {
            owner = "projekt0n";
            repo = "github-nvim-theme";
            rev = "98db85c8a12307e3b1bc8da48ddf76d8484e9e90";
            hash = "sha256-AxtZd6sPHVl8HR0tPGkV4MUi40yV7EJRDIPc0NuCWEM=";
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
          version = "2024-08-27";
          src = pkgs.fetchFromGitHub {
            owner = "diegoulloao";
            repo = "neofusion.nvim";
            rev = "c0fc7b41057fbb69dd9ff6fd2d913b1f532effac";
            hash = "sha256-Urnb4N8FYlfCm8j4LYgWEvLwzR9zbTZadJJfELqWRMU=";
          };
        };

        tiny-inline-diagnostic-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "tiny-inline-diagnostic.nvim";
          version = "2024-09-10";
          src = pkgs.fetchFromGitHub {
            owner = "rachartier";
            repo = "tiny-inline-diagnostic.nvim";
            rev = "c0543b2980251a7a2024e936ef724dcdfb07bb87";
            hash = "sha256-UOJf4Oi38Bj8xRHGGV+XWvOlOez6jm908NuThWUQyIU=";
          };
        };

        # Temp reference for mini.icons until unstable updates
        # my-mini-nvim = pkgs.vimUtils.buildVimPlugin {
        #   pname = "mini.nvim";
        #   version = "2024-07-07";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "echasnovski";
        #     repo = "mini.nvim";
        #     rev = "45b3540003566e8f19c4cc4b1c9d0b8605a2697c";
        #     sha256 = "sha256-kA8yDJrnKLlg27rKsAdxp3vTBF2ZT2uCIIY103unHeo=";
        #   };
        #   meta.homepage = "https://github.com/echasnovski/mini.nvim/";
        # };

        my-lazy-lsp-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "lazy-lsp.nvim";
          version = "2024-09-21";
          src = pkgs.fetchFromGitHub {
            owner = "danruto";
            repo = "lazy-lsp.nvim";
            rev = "d2028b68ddb132b987874ddf220ffbc6afe7e5f3";
            hash = "sha256-rlAuS5Ij2rCGppJXUCVvZgO/wrgQzrTBxskoWgGYAQw=";
          };
        };

        markdown-render-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "markdown.nvim";
          version = "2024-07-21";
          src = pkgs.fetchFromGitHub {
            owner = "MeanderingProgrammer";
            repo = "markdown.nvim";
            rev = "123048b428eb85618780fcef9ea9f4d68b5d2508";
            hash = "sha256-YWcpS8K8ykAnC2qDXhl6kteSJ9pwxT4WXMqsFrwX7WM=";
          };
        };

        perf-nvim-cmp = pkgs.vimUtils.buildVimPlugin {
          pname = "nvim-cmp";
          version = "2024-08-27";
          src = pkgs.fetchFromGitHub {
            owner = "yioneko";
            repo = "nvim-cmp";
            rev = "6c3d595f3223c1ae7392d4fde1626355439af6c1";
            hash = "sha256-qVU02nIclxt5Fgh+8Cll087AoWtaLo4g2846VYf+ALY=";
          };
        };

        neocodeium = pkgs.vimUtils.buildVimPlugin {
          pname = "neocodeium";
          version = "2024-09-10";
          src = pkgs.fetchFromGitHub {
            owner = "monkoose";
            repo = "neocodeium";
            rev = "f45d2e2fda4889f507776d9102850359a5ce1d0f";
            hash = "sha256-R6+oovZ2uMIJG5Ekremtctt1h8OjpwEGInyCS58FTag=";
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
          # nvim-cmp
          perf-nvim-cmp
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
          tiny-inline-diagnostic-nvim
          trouble-nvim
          telescope-nvim
          neo-tree-nvim
          markdown-render-nvim
          neocodeium

          # ---- Themes ----

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
          # lazy-lsp-nvim
          my-lazy-lsp-nvim
          # lsp_lines-nvim
          # nvim-spectre
          todo-comments-nvim
          pineapple-nvim
          # codeium-nvim
          dropbar-nvim
          telescope-fzf-native-nvim
          { name = "catppuccin"; path = catppuccin-nvim; }
          monet-nvim
          neofusion-nvim
          oxocarbon-nvim







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

