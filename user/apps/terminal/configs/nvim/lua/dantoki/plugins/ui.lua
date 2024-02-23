return {
	{
		"nvim-tree/nvim-web-devicons",
		opts = {},
	},
	{
		"rcarriga/nvim-notify",
		config = function()
			vim.notify = require("notify")
		end,
	},
	{
		"stevearc/dressing.nvim",
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
		opts = {
			overlay_opacity = 50,
			opacity_step = 1,
			keys = {
				brightness_up = "<C-Up>",
				brightness_down = "<C-Down>",
				toggle = "<Leader>ss",
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
		"ziontee113/icon-picker.nvim",
		cmd = {
			"IconPickerNormal",
			"IconPickerYank",
			"IconPickerInsert",
		},
		dependencies = {
			"stevearc/dressing.nvim",
		},
		opts = {
			disable_legacy_commands = true,
		},
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
		opts = {},
	},
	{
		"folke/trouble.nvim",
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
	},
	{
		"nvim-pack/nvim-spectre",
		opts = {},
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},
}
