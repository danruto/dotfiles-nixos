local finder = {
	telescope = false,
	jfind = false,
	azy = false,
	snacks = true,
}

return {
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		enabled = finder.telescope,
		config = function()
			require("dantoki.configs.telescope")
		end,
		keys = {
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
							tb.git_files({ show_untracked = true })
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
									-- catppuccin is catppuccin/nvim which is different to the norm, so skip that one specifically
									if k ~= "nvim" then
										table.insert(plugins, k)
									end
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
			{ "<Space>/", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
			-- { ";", "<cmd>Telescope buffers show_all_buffers=true<cr>", desc = "Show buffers" },
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
		},
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		-- TODO: Enable once explorer is in the nix snacks version
		enabled = not finder.snacks,
		event = { "BufReadPre", "BufNewFile" },
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		keys = {
			{ "<Space>e", "<cmd>Neotree toggle<cr>", desc = "NeoTree" },
		},
		opts = {
			sources = { "filesystem", "buffers", "git_status", "document_symbols" },
			open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
			filesystem = {
				bind_to_cwd = false,
				follow_current_file = {
					enabled = true,
				},
				use_libuv_file_watcher = true,
			},
		},
	},
	{
		"jake-stewart/jfind.nvim",
		branch = "1.0",
		enabled = finder.jfind,
		build = "git clone https://github.com/jake-stewart/jfind && cd jfind && cmake -S . -B build && cd build && sudo make install && cd../../ && rm -rf jfind",
		opts = {
			exclude = {
				".git",
				".idea",
				".vscode",
				".sass-cache",
				".class",
				"__pycache__",
				"node_modules",
				"target",
				"build",
				"tmp",
				"assets",
				"dist",
				"public",
				"*.iml",
				"*.meta",
			},
			border = "rounded",
		},
		keys = {
			{
				"<Space>f",
				function()
					local ok, jfind = pcall(require, "jfind")

					if not ok then
						return
					end

					jfind.findFile()
				end,
			},
		},
	},
	{
		"https://git.sr.ht/~vigoux/azy.nvim",
		enabled = finder.azy,
		build = "make lib",
	},
	{
		enabled = finder.snacks,
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
			animate = { enabled = false },
			bigfile = { enabled = true },
			dashboard = {
				enabled = true,
				preset = {
					header = [[
██████╗ ██╗██╗  ██╗███████╗██╗         ██████╗ ██████╗ ██╗   ██╗███████╗██╗  ██╗
██╔══██╗██║╚██╗██╔╝██╔════╝██║         ██╔══██╗██╔══██╗██║   ██║██╔════╝██║  ██║
██████╔╝██║ ╚███╔╝ █████╗  ██║         ██████╔╝██████╔╝██║   ██║███████╗███████║
██╔═══╝ ██║ ██╔██╗ ██╔══╝  ██║         ██╔══██╗██╔══██╗██║   ██║╚════██║██╔══██║
██║     ██║██╔╝ ██╗███████╗███████╗    ██████╔╝██║  ██║╚██████╔╝███████║██║  ██║
╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
]],
				},
			},
			dim = { enabled = true },
			explorer = { enabled = true },
			gitbrowse = { enabled = false },
			indent = { enabled = true },
			input = { enabled = true },
			layout = { enabled = true },
			lazygit = { enabled = false },
			notifier = { enabled = true },
			picker = { enabled = true, exclude = { "vendor/*" } },
			quickfile = { enabled = true },
			scope = { enabled = true },
			scratch = { enabled = true },
			scroll = { enabled = false },
			statuscolumn = { enabled = true },
			terminal = { enabled = true },
			toggle = { enabled = false },
			win = { enabled = false },
			words = { enabled = true },
			zen = { enabled = true },
		},
		keys = {
			{
				"<leader><leader>",
				function()
					Snacks.picker.smart()
				end,
				desc = "Smart Find Files",
			},
			{
				"<Space>f",
				function()
					local function files_fallback()
						vim.fn.system("git rev-parse --is-inside-work-tree")
						if vim.v.shell_error == 0 then
							Snacks.picker.git_files()
						else
							Snacks.picker.files()
						end
					end

					files_fallback()
				end,
				desc = "Find Files (Git if in .git)",
			},
			{
				"<Space>c",
				function()
					Snacks.picker.colorschemes()
				end,
				desc = "Colorschemes",
			},
			{
				"<Space>b",
				function()
					Snacks.picker.buffers()
				end,
				desc = "Buffers",
			},
			{
				"<Space>e",
				function()
					Snacks.explorer()
				end,
				desc = "File Explorer",
			},
			{
				"<Space>/",
				function()
					Snacks.picker.grep()
				end,
				desc = "Grep",
			},
			{
				"gd",
				function()
					Snacks.picker.lsp_definitions()
				end,
				desc = "Goto Definition",
			},
			{
				"gD",
				function()
					Snacks.picker.lsp_declarations()
				end,
				desc = "Goto Declaration",
			},
			{
				"gr",
				function()
					Snacks.picker.lsp_references()
				end,
				nowait = true,
				desc = "References",
			},
			{
				"gI",
				function()
					Snacks.picker.lsp_implementations()
				end,
				desc = "Goto Implementation",
			},
			{
				"gy",
				function()
					Snacks.picker.lsp_type_definitions()
				end,
				desc = "Goto T[y]pe Definition",
			},
			{
				"<Space>s",
				function()
					Snacks.picker.lsp_symbols()
				end,
				desc = "LSP Symbols",
			},
			{
				"<Space>S",
				function()
					Snacks.picker.lsp_workspace_symbols()
				end,
				desc = "LSP Workspace Symbols",
			},
			{
				"<Space>d",
				function()
					Snacks.picker.diagnostics()
				end,
				desc = "Diagnostics",
			},
			{
				"]]",
				function()
					Snacks.words.jump(vim.v.count1)
				end,
				desc = "Next Reference",
				mode = { "n", "t" },
			},
			{
				"[[",
				function()
					Snacks.words.jump(-vim.v.count1)
				end,
				desc = "Prev Reference",
				mode = { "n", "t" },
			},
			{
				"<leader>z",
				function()
					Snacks.zen()
				end,
				desc = "Toggle Zen Mode",
			},
		},
		init = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()
					-- Setup some globals for debugging (lazy-loaded)
					_G.dd = function(...)
						Snacks.debug.inspect(...)
					end
					_G.bt = function()
						Snacks.debug.backtrace()
					end
					vim.print = _G.dd -- Override print to use snacks for `:=` command

					-- Create some toggle mappings
					Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
					Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
					Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
					Snacks.toggle.diagnostics():map("<leader>ud")
					Snacks.toggle.line_number():map("<leader>ul")
					Snacks.toggle
						.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
						:map("<leader>uc")
					Snacks.toggle.treesitter():map("<leader>uT")
					Snacks.toggle
						.option("background", { off = "light", on = "dark", name = "Dark Background" })
						:map("<leader>ub")
					Snacks.toggle.inlay_hints():map("<leader>uh")
					Snacks.toggle.indent():map("<leader>ug")
					Snacks.toggle.dim():map("<leader>uD")
				end,
			})
		end,
	},
}
