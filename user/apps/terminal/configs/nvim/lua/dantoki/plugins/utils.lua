local finder = {
	telescope = true,
	jfind = false,
	azy = false,
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
		},
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
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
}
