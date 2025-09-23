return {
	{
		"nvim-tree/nvim-web-devicons",
		opts = {},
	},
	{
		"rcarriga/nvim-notify",
		enabled = false,
		config = function()
			vim.notify = require("notify")
		end,
	},
	{
		"stevearc/dressing.nvim",
		enabled = false,
		init = function()
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.select = function(...)
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.select(...)
			end
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.input = function(...)
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.input(...)
			end
		end,
	},
	{
		"jghauser/shade.nvim",
		enabled = false,
		opts = {
			overlay_opacity = 50,
			opacity_step = 1,
			keys = {
				brightness_up = "<C-Up>",
				brightness_down = "<C-Down>",
				toggle = "<Leader>ts",
			},
			exclude_filetypes = { "CHADTree", "neo-tree", "Mason" },
		},
	},
	{
		"tjdevries/express_line.nvim",
		enabled = false,
		lazy = false,
		priority = 800,
		config = function()
			require("dantoki.configs.expressline")
		end,
	},
	{
		"NvChad/nvim-colorizer.lua",
		event = "User ActuallyEditing",
		opts = {
			filetypes = { "*", "!lazy" },
			buftype = { "*", "!prompt", "!nofile" },
			user_default_options = {
				RGB = true, -- #RGB hex codes
				RRGGBB = true, -- #RRGGBB hex codes
				names = false, -- "Name" codes like Blue
				RRGGBBAA = true, -- #RRGGBBAA hex codes
				AARRGGBB = false, -- 0xAARRGGBB hex codes
				rgb_fn = true, -- CSS rgb() and rgba() functions
				hsl_fn = true, -- CSS hsl() and hsla() functions
				css = false, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
				css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
				-- Available modes: foreground, background
				-- Available modes for `mode`: foreground, background,  virtualtext
				mode = "background", -- Set the display mode.
				virtualtext = "■",
			},
		},
	},
	{
		"Pocco81/true-zen.nvim",
		enabled = false,
		cmd = {
			"TZAtaraxis",
			"TZMinimalist",
			"TZFocus",
			"TZNarrow",
		},
		opts = {},
	},
	{
		"sindrets/winshift.nvim",
		enabled = false,
		opts = {},
	},
	{
		"folke/trouble.nvim",
		enabled = false,
		cmd = "Trouble",
		keys = {
			{
				"<Leader>n",
				function()
					local ok, t = pcall(require, "trouble")
					if not ok then
						return
					end
					t.next({ skip_groups = true, jump = true })
				end,
				desc = "Jump to next diagnostic",
			},
		},
		opts = {
			use_diagnostic_signs = true,
		},
	},
	-- {
	-- 	"nvim-pack/nvim-spectre",
	-- 	opts = {
	-- 		open_cmd = "noswapfile vnew",
	-- 	},
	-- },
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		cmd = "RenderMarkdown",
		dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use standalone mini plugins
		opts = {},
	},
	{
		"3rd/diagram.nvim",
		dependencies = {
			{ "3rd/image.nvim", opts = { backend = "kitty" } },
		},
		cmd = "RenderMarkdown",
		-- ft = { "markdown" }, -- disable due to non-kitty terms like foot having issues
		opts = { -- you can just pass {}, defaults below
			events = {
				render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
				clear_buffer = { "BufLeave" },
			},
			renderer_options = {
				mermaid = {
					background = nil, -- nil | "transparent" | "white" | "#hex"
					theme = nil, -- nil | "default" | "dark" | "forest" | "neutral"
					scale = 1, -- nil | 1 (default) | 2  | 3 | ...
					width = nil, -- nil | 800 | 400 | ...
					height = nil, -- nil | 600 | 300 | ...
				},
				plantuml = {
					charset = nil,
				},
				d2 = {
					theme_id = nil,
					dark_theme_id = nil,
					scale = nil,
					layout = nil,
					sketch = nil,
				},
				gnuplot = {
					size = nil, -- nil | "800,600" | ...
					font = nil, -- nil | "Arial,12" | ...
					theme = nil, -- nil | "light" | "dark" | custom theme string
				},
			},
		},
	},
	{
		"kndndrj/nvim-dbee",
		enabled = false,
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		-- build = function()
		-- 	-- Install tries to automatically detect the install method.
		-- 	-- if it fails, try calling it with one of these parameters:
		-- 	--    "curl", "wget", "bitsadmin", "go"
		-- 	require("dbee").install()
		-- end,
		config = function()
			require("dbee").setup(--[[optional config]])
		end,
	},
	{
		"MagicDuck/grug-far.nvim",
		opts = { headerMaxWidth = 80 },
		cmd = { "GrugFar", "GrugFarWithin" },
		keys = {
			{
				"<leader>sr",
				function()
					local grug = require("grug-far")
					local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
					grug.open({
						transient = true,
						prefills = {
							filesFilter = ext and ext ~= "" and "*." .. ext or nil,
						},
					})
				end,
				mode = { "n", "v" },
				desc = "Search and Replace",
			},
		},
	},
}
