return {
	"windwp/nvim-ts-autotag",
	"editorconfig/editorconfig-vim",
	"alvan/vim-closetag",
	"AndrewRadev/tagalong.vim",
	{
		"nvim-treesitter/nvim-treesitter",
		version = false,
		dependencies = {
			"nvim-treesitter/nvim-treesitter-refactor",
			"RRethy/nvim-treesitter-textsubjects",
			"RRethy/nvim-treesitter-endwise",
		},
		build = ":TSUpdate",
		event = "User ActuallyEditing",
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
			ensure_installed = {
				"bash",
				"c",
				"cmake",
				-- "comment", -- comments are slowing down TS bigtime, so disable for now
				"cpp",
				"css",
				"diff",
				"fish",
				"gitignore",
				"go",
				"graphql",
				"html",
				"http",
				-- "java",
				"javascript",
				"jsdoc",
				"jsonc",
				"json",
				-- "latex",
				"lua",
				"markdown",
				"markdown_inline",
				"meson",
				-- "ninja",
				"nix",
				-- "norg",
				-- "org",
				-- "php",
				"python",
				"query",
				"regex",
				"rust",
				"scss",
				"sql",
				-- "svelte",
				-- "teal",
				"toml",
				"tsx",
				"typescript",
				-- "vhs",
				"vim",
				"vue",
				-- "wgsl",
				"yaml",
			},
			highlight = {
				enable = true,
				use_languagetree = true,
			},
			auto_install = true,
		},
		---@param opts TSConfig
		config = function(_, opts)
			if type(opts.ensure_installed) == "table" then
				---@type table<string, boolean>
				local added = {}
				opts.ensure_installed = vim.tbl_filter(function(lang)
					if added[lang] then
						return false
					end
					added[lang] = true
					return true
				end, opts.ensure_installed)
			end
			require("nvim-treesitter.configs").setup(opts)
		end,
	},
	--[[{
		"ggandor/flit.nvim",
		dependencies = "ggandor/leap.nvim",
		keys = { "f", "t" },
		opts = {},
	},]]
	--
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		---@type Flash.Config
		opts = {},
        -- stylua: ignore
        keys = {
          { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
          { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
          { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
          { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
          --- { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
        },
	},
	{
		"echasnovski/mini.nvim",
		config = function()
			-- require("mini.ai").setup()
			-- require("mini.animate").setup()
			require("mini.bracketed").setup()
			require("mini.comment").setup()
			require("mini.cursorword").setup()
			require("mini.doc").setup()
			require("mini.indentscope").setup()
			require("mini.pairs").setup()
			require("mini.splitjoin").setup()
			require("mini.surround").setup()
			require("mini.trailspace").setup()
		end,
	},
}
