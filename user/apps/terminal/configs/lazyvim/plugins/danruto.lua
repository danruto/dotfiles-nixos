return {
  { "folke/tokyonight.nvim" },
  { "Shatur/neovim-ayu" },
  { "NLKNguyen/papercolor-theme" },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
  },

  -- add tsserver and setup with typescript.nvim instead of lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "jose-elias-alvarez/typescript.nvim",
      init = function()
        require("lazyvim.util").lsp.on_attach(function(_, buffer)
          -- stylua: ignore
          vim.keymap.set( "n", "<leader>co", "TypescriptOrganizeImports", { buffer = buffer, desc = "Organize Imports" })
          vim.keymap.set("n", "<leader>cR", "TypescriptRenameFile", { desc = "Rename File", buffer = buffer })
        end)
      end,
    },
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- tsserver will be automatically installed with mason and loaded with lspconfig
        tsserver = {},
      },
      -- you can do any additional lsp server setup here
      -- return true if you don't want this server to be setup with lspconfig
      ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
      setup = {
        -- example to setup with typescript.nvim
        tsserver = function(_, opts)
          require("typescript").setup({ server = opts })
          return true
        end,
        -- Specify * to use this function as a fallback for any server
        -- ["*"] = function(server, opts) end,
      },
    },
  },

  -- for typescript, LazyVim also includes extra specs to properly setup lspconfig,
  -- treesitter, mason and typescript.nvim. So instead of the above, you can use:
  { import = "lazyvim.plugins.extras.lang.docker" },
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lang.rust" },
  { import = "lazyvim.plugins.extras.lang.tailwind" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.go" },

  { import = "lazyvim.plugins.extras.editor.navic" },

  {
    "nvim-telescope/telescope.nvim",
    -- replace all Telescope keymaps with only one mapping
    keys = function()
      return {
        {
          "<Space>f",
          function()
            local tb_ok, tb = pcall(require, "telescope.builtin")

            if not tb_ok then
              return
            end

            local function files_fallback()
              vim.fn.system("git rev-parse --is-inside-work-tree")
              if vim.v.shell_error == 0 then
                tb.git_files()
              else
                tb.find_files()
              end
            end

            files_fallback()
          end,
          desc = "Files explorer",
        },
        {
          "<Space>c",
          function()
            local tb_ok, tb = pcall(require, "telescope.builtin")

            if not tb_ok then
              return
            end

            -- Insert our known colourschemes because they are lazy loaded

            local plugins = {}
            for _, tbl in pairs(require("dantoki.plugins.themes")) do
              for key, value in pairs(tbl) do
                if type(value) == "string" then
                  if type(key) == "number" then
                    local k = ""
                    for nk, _ in string.gmatch(value, "[^/]+") do
                      -- We only want the second value but lua kinda sucks
                      -- and we're lazy so just overwrite with whatever the last value is
                      k = nk
                    end
                    table.insert(plugins, k)
                  end
                end
              end
            end

            require("lazy").load({ plugins = plugins })

            tb.colorscheme({
              enable_preview = true,
            })
          end,
          desc = "Theme selector",
        },
        {
          "<Space>C",
          "<cmd>Telescope themes<cr>",
          desc = "Theme selector",
        },
        { "<Space>/", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
        { ";", "<cmd>Telescope buffers show_all_buffers=true<cr>", desc = "Show buffers" },
        {
          "gd",
          function()
            local tb_ok, tb = pcall(require, "telescope.builtin")

            if not tb_ok then
              return
            end

            tb.lsp_definitions()
          end,
          desc = "Go to definition",
        },
        {
          "gD",
          function()
            local tb_ok, tb = pcall(require, "telescope.builtin")

            if not tb_ok then
              return
            end

            tb.lsp_type_definitions()
          end,
          desc = "Go to type definition",
        },
        {
          "gr",
          function()
            local tb_ok, tb = pcall(require, "telescope.builtin")

            if not tb_ok then
              return
            end

            tb.lsp_references()
          end,
          desc = "Go to reference",
        },
        {
          "gi",
          function()
            local tb_ok, tb = pcall(require, "telescope.builtin")

            if not tb_ok then
              return
            end

            tb.lsp_implementations()
          end,
          desc = "Go to implementation",
        },
        {
          "<Leader>S",
          function()
            local tb_ok, tb = pcall(require, "telescope.builtin")

            if not tb_ok then
              return
            end

            tb.lsp_workspace_symbols()
          end,
          desc = "Go to workspace symbols",
        },
        {
          "<Leader>s",
          function()
            local tb_ok, tb = pcall(require, "telescope.builtin")

            if not tb_ok then
              return
            end

            tb.lsp_document_symbols()
          end,
          desc = "Go to document symbols",
        },
        {
          "<Leader>d",
          function()
            local tb_ok, tb = pcall(require, "telescope.builtin")

            if not tb_ok then
              return
            end

            tb.diagnostics()
          end,
          desc = "Go to diagnostics",
        },
      }
    end,
  },

}
