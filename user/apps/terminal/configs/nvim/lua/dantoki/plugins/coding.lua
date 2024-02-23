return {
	"windwp/nvim-ts-autotag",
	"editorconfig/editorconfig-vim",
	"alvan/vim-closetag",
	"AndrewRadev/tagalong.vim",
	{
		"nvim-treesitter/nvim-treesitter",
		version = false,
		dependencies = {
			{
				"nvim-treesitter/nvim-treesitter-context",
				opts = { mode = "cursor", max_lines = 3 },
			},
			"nvim-treesitter/nvim-treesitter-refactor",
			"nvim-treesitter/nvim-treesitter-textobjects",
			"RRethy/nvim-treesitter-textsubjects",
			"RRethy/nvim-treesitter-endwise",
		},
		build = ":TSUpdate",
		event = { "VeryLazy" },
		cmd = {
			"TSInstall",
			"TSBufEnable",
			"TSBufDisable",
			"TSEnable",
			"TSDisable",
			"TSModuleInfo",
			"TSUpdate",
		},
		---@type TSConfig
		opts = {
			highlight = {
				enable = true,
				use_languagetree = true,
			},
		},
	},
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		---@type Flash.Config
		opts = {},
        -- stylua: ignore
        keys = {
            { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
            { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
            { "r", mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
            { "R", mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
            --- { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
        },
	},
	"JoosepAlviste/nvim-ts-context-commentstring",
	{
		"echasnovski/mini.nvim",
		config = function()
			-- require("mini.ai").setup()
			-- require("mini.animate").setup()
			require("mini.bracketed").setup()
			require("mini.comment").setup({
				options = {
					custom_commentstring = function()
						return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
					end,
				},
			})
			require("mini.cursorword").setup()
			require("mini.doc").setup()
			require("mini.indentscope").setup()
			require("mini.pairs").setup()
			require("mini.splitjoin").setup()
			require("mini.surround").setup()
			require("mini.statusline").setup()
			require("mini.trailspace").setup()
		end,
	},
}
