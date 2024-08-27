return {
	{
		"tokyonight.nvim",
		opts = {
			transparent = true,
			styles = {
				sidebars = "transparent",
				floats = "transparent",
			},
		},
	},
	{ "Shatur/neovim-ayu" },
	{ "NLKNguyen/papercolor-theme" },
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "tokyonight-night",
		},
	},
	{ "yuttie/snowy-vim" },
	{ "igorgue/danger" },
	-- { "rebelot/kanagawa.nvim" },
	{ "water-sucks/darkrose.nvim" },
	{ "barrientosvctor/abyss.nvim" },
	-- { "m-t3k/tartessos.nvim" },
	-- { "liminalminds/icecream.nvim" },

	-- add tsserver and setup with typescript.nvim instead of lspconfig
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"jose-elias-alvarez/typescript.nvim",
			init = function()
				require("lazyvim.util").lsp.on_attach(function(_, buffer)
                    -- stylua: ignore
                    vim.keymap.set("n", "<leader>co", "TypescriptOrganizeImports",
                        { buffer = buffer, desc = "Organize Imports" })
					vim.keymap.set("n", "<leader>cR", "TypescriptRenameFile", { desc = "Rename File", buffer = buffer })
				end)
			end,
		},
		---@class PluginLspOpts
		opts = {
			---@type lspconfig.options
			servers = {
				-- tsserver will be automatically installed with mason and loaded with lspconfig
				-- tsserver = {},
				-- graphql = {},
			},
			-- you can do any additional lsp server setup here
			-- return true if you don't want this server to be setup with lspconfig
			---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
			setup = {
				-- example to setup with typescript.nvim
				-- tsserver = function(_, opts)
				--     require("typescript").setup({ server = opts })
				--     return true
				-- end,
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
		keys = {
			{ ";", "<cmd>Telescope buffers show_all_buffers=true<cr>", desc = "Show buffers" },
		},
		opts = {
			defaults = {

				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
				},
				initial_mode = "insert",
				selection_strategy = "reset",
				sorting_strategy = "ascending",
				layout_strategy = "vertical",
				layout_config = {
					horizontal = {
						prompt_position = "bottom",
						preview_width = 0.55,
						results_width = 0.8,
					},
					vertical = {
						mirror = false,
					},
					width = 0.87,
					height = 0.80,
					preview_cutoff = 120,
				},
				color_devicons = true,
			},
			pickers = { colorscheme = { enable_preview = true } },
		},
	},

	-- {
	--   "nvim-telescope/telescope.nvim",
	--   -- replace all Telescope keymaps with only one mapping
	--   keys = function()
	--     return {
	--       {
	--         "<Space>f",
	--         function()
	--           local tb_ok, tb = pcall(require, "telescope.builtin")
	--
	--           if not tb_ok then
	--             return
	--           end
	--
	--           local function files_fallback()
	--             vim.fn.system("git rev-parse --is-inside-work-tree")
	--             if vim.v.shell_error == 0 then
	--               tb.git_files()
	--             else
	--               tb.find_files()
	--             end
	--           end
	--
	--           files_fallback()
	--         end,
	--         desc = "Files explorer",
	--       },
	--       {
	--         "<Space>c",
	--         function()
	--           local tb_ok, tb = pcall(require, "telescope.builtin")
	--
	--           if not tb_ok then
	--             return
	--           end
	--
	--           -- Insert our known colourschemes because they are lazy loaded
	--
	--           local plugins = {}
	--           for _, tbl in pairs(require("dantoki.plugins.themes")) do
	--             for key, value in pairs(tbl) do
	--               if type(value) == "string" then
	--                 if type(key) == "number" then
	--                   local k = ""
	--                   for nk, _ in string.gmatch(value, "[^/]+") do
	--                     -- We only want the second value but lua kinda sucks
	--                     -- and we're lazy so just overwrite with whatever the last value is
	--                     k = nk
	--                   end
	--                   table.insert(plugins, k)
	--                 end
	--               end
	--             end
	--           end
	--
	--           require("lazy").load({ plugins = plugins })
	--
	--           tb.colorscheme({
	--             enable_preview = true,
	--           })
	--         end,
	--         desc = "Theme selector",
	--       },
	--       {
	--         "<Space>C",
	--         "<cmd>Telescope themes<cr>",
	--         desc = "Theme selector",
	--       },
	--       { "<Space>/", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
	--       { ";", "<cmd>Telescope buffers show_all_buffers=true<cr>", desc = "Show buffers" },
	--       {
	--         "gd",
	--         function()
	--           local tb_ok, tb = pcall(require, "telescope.builtin")
	--
	--           if not tb_ok then
	--             return
	--           end
	--
	--           tb.lsp_definitions()
	--         end,
	--         desc = "Go to definition",
	--       },
	--       {
	--         "gD",
	--         function()
	--           local tb_ok, tb = pcall(require, "telescope.builtin")
	--
	--           if not tb_ok then
	--             return
	--           end
	--
	--           tb.lsp_type_definitions()
	--         end,
	--         desc = "Go to type definition",
	--       },
	--       {
	--         "gr",
	--         function()
	--           local tb_ok, tb = pcall(require, "telescope.builtin")
	--
	--           if not tb_ok then
	--             return
	--           end
	--
	--           tb.lsp_references()
	--         end,
	--         desc = "Go to reference",
	--       },
	--       {
	--         "gi",
	--         function()
	--           local tb_ok, tb = pcall(require, "telescope.builtin")
	--
	--           if not tb_ok then
	--             return
	--           end
	--
	--           tb.lsp_implementations()
	--         end,
	--         desc = "Go to implementation",
	--       },
	--       {
	--         "<Leader>S",
	--         function()
	--           local tb_ok, tb = pcall(require, "telescope.builtin")
	--
	--           if not tb_ok then
	--             return
	--           end
	--
	--           tb.lsp_workspace_symbols()
	--         end,
	--         desc = "Go to workspace symbols",
	--       },
	--       {
	--         "<Leader>s",
	--         function()
	--           local tb_ok, tb = pcall(require, "telescope.builtin")
	--
	--           if not tb_ok then
	--             return
	--           end
	--
	--           tb.lsp_document_symbols()
	--         end,
	--         desc = "Go to document symbols",
	--       },
	--       {
	--         "<Leader>d",
	--         function()
	--           local tb_ok, tb = pcall(require, "telescope.builtin")
	--
	--           if not tb_ok then
	--             return
	--           end
	--
	--           tb.diagnostics()
	--         end,
	--         desc = "Go to diagnostics",
	--       },
	--     }
	--   end,
	-- },
	--

	{
		-- "hrsh7th/nvim-cmp",
		"yioneko/nvim-cmp",
		keys = {
			{ "<Leader>a", vim.lsp.buf.code_action, desc = "Code actions" },
			{ "<Leader>rn", vim.lsp.buf.rename, desc = "Rename" },
		},
		---@param opts cmp.ConfigSchema
		opts = function(_, opts)
			local has_words_before = function()
				unpack = unpack or table.unpack
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			end

			local luasnip = require("luasnip")
			local cmp = require("cmp")

			opts.mapping = vim.tbl_extend("force", opts.mapping, {
				["<Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						-- You could replace select_next_item() with confirm({ select = true }) to get VS Code autocompletion behavior
						cmp.select_next_item()
						-- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
						-- this way you will only jump inside the snippet region
					elseif luasnip.expand_or_jumpable() then
						luasnip.expand_or_jump()
					elseif has_words_before() then
						cmp.complete()
					else
						fallback()
					end
				end, { "i", "s" }),
				["<S-Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					elseif luasnip.jumpable(-1) then
						luasnip.jump(-1)
					else
						fallback()
					end
				end, { "i", "s" }),
			})
		end,
	},

	{
		"stevearc/conform.nvim",
		---@param opts ConformOpts
		opts = {
			formatters_by_ft = {
				json = { "fixjson" },
				python = { "isort", "black" },
				nix = { "nixpkgs_fmt" },
			},
		},
	},

	{
		"mfussenegger/nvim-lint",
		opts = {
			linters_by_ft = {
				python = { "ruff" },
				typescript = { "eslint_d" },
				["yaml.cloudformation"] = { "cfn_lint", "cfn_nag" },
				["yaml.github_actions"] = { "actionlint" },
				go = { "golangcilint" },
				dockerfile = { "hadolint" },
			},
		},
	},
}
