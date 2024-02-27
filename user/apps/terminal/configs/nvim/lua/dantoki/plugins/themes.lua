return {
	{
		"projekt0n/github-nvim-theme",
		config = function() end,
	},
	{
		"Shatur/neovim-ayu",
		config = function() end,
	},
	-- {
	-- 	"nocksock/bloop.nvim",
	-- 	dependencies = { "rktjmp/lush.nvim" },
	-- 	config = function() end,
	-- },
	{
		"NLKNguyen/papercolor-theme",
		config = function()
			-- vim.cmd([[ colorscheme papercolor ]])
		end,
	},
	{
		"yuttie/snowy-vim",
		config = function()
			-- vim.cmd([[ colorscheme snowy ]])
		end,
	},
	{
		"Yazeed1s/oh-lucy.nvim",
		config = function()
			-- vim.cmd([[ colorscheme oh-lucy ]])
		end,
	},
	-- {
	--     "arturgoms/moonbow.nvim",
	--     config = function()
	--         -- vim.cmd([[ colorscheme moonbow ]])
	--     end,
	-- },
	{
		"igorgue/danger",
		-- lazy = false,
		-- priority = 1000,
		opts = {
			style = "dark",
			-- alacritty = true,
		},
		keys = {
			{
				"<leader>D",
				function()
					if vim.g.colors_name == "danger_dark" then
						vim.cmd("colorscheme danger_light")
					else
						vim.cmd("colorscheme danger_dark")
					end
				end,
				desc = "Toggle Danger dark mode",
			},
		},
	},
	-- {
	-- 	"uloco/bluloco.nvim",
	-- 	dependencies = { "rktjmp/lush.nvim" },
	-- 	opts = {
	-- 		style = "light",
	-- 	},
	-- },
	-- {
	-- 	"themercorp/themer.lua",
	-- 	opts = {
	-- 		enable_installer = true,
	-- 	},
	-- },
	-- {
	--     "dharmx/nvim-colo",
	--     commit = "a401cad1762b458332d563484c05eb149bfa7a48",
	--     cmd = { "Colo", "ColoTele" },
	--     opts = {
	--         manual = true,
	--     },
	--     requires = {
	--         "nvim-lua/plenary.nvim",
	--     },
	-- },
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd([[ colorscheme tokyonight-night ]])
		end,
		opts = {
			style = "night",
		},
	},
	-- { "Alexis12119/nightly.nvim" },
	{
		"echasnovski/mini.hues",
		version = false,
		-- lazy = false,
		-- priority = 1000,
		opts = {
			background = "#0a0e14",
			foreground = "#73d0ff",
			saturation = "high",
		},
	},
	{
		"CWood-sdf/pineapple",
		-- dependencies = require("dantoki.pineapple"),
		opts = {
			installedRegistry = "dantoki.pineapple",
			colorschemeFile = "after/plugin/theme.lua",
		},
		cmd = "Pineapple",
	},
}
