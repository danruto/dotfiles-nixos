return {
	{
		"Exafunction/codeium.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		event = "LspAttach",
		cmd = "Codeium",
		build = ":Codeium Auth",
		opts = {},
		enabled = false,
	},
	{
		"monkoose/neocodeium",
		event = "VeryLazy",
		cmd = "NeoCodeium",
		build = ":NeoCodeium auth",
		config = function()
			local neocodeium = require("neocodeium")
			neocodeium.setup()
			vim.keymap.set("i", "<C-a>", function()
				require("neocodeium").accept()
			end)
			vim.keymap.set("i", "<A-e>", function()
				require("neocodeium").cycle_or_complete()
			end)
			vim.keymap.set("i", "<A-r>", function()
				require("neocodeium").cycle_or_complete(-1)
			end)
		end,
	},
	{
		"zbirenbaum/copilot.lua",
		enabled = false,
		cmd = "Copilot",
		event = "InsertEnter",
		opts = {
			suggestion = { enabled = false },
			panel = { enabled = false },
		},
	},
	{
		"dundalek/lazy-lsp.nvim",
		event = "InsertEnter",
		dependencies = {
			"neovim/nvim-lspconfig",
		},
		init = function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ 0 }), { 0 })
		end,
		opts = {
			excluded_servers = {
				"sqls",
				"denols",
				"flow",
				"nixd",
				"tsserver",
				"rust_analyzer",
				"bazelrc-lsp",
				"ruff_lsp",
				"bufls",
				"typst_lsp",
			},
			preferred_servers = {
				python = { "basedpyright", "ruff" },
				-- rust = { "rust_analyzer" },
				rust = {},
				-- nix = { "nil" },
				javascript = { "tsserver" },
				javascriptreact = {},
				["javascript.tsx"] = {},
				typescript = { "biome", "eslint" },
				typescriptreact = { "biome", "eslint" },
				["typescript.tsx"] = {},
				-- typescript = { "typescript-tools" },
				-- ["typescript.tsx"] = { "typescript-tools" },
				-- typescriptreact = { "typescript-tools" },
				go = { "gopls" },
				yaml = { "yamlls" },
				zig = { "zls" },
			},
			prefer_local = true,
			configs = {
				-- rust_analyzer = {
				-- keys = {
				-- 	{ "K", "<cmd>RustHoverActions<cr>", desc = "Hover Actions (Rust)" },
				-- 	{ "<leader>cR", "<cmd>RustCodeAction<cr>", desc = "Code Action (Rust)" },
				-- 	{ "<leader>dr", "<cmd>RustDebuggables<cr>", desc = "Run Debuggables (Rust)" },
				-- },
				-- settings = {
				-- 	["rust-analyzer"] = {
				-- 		cargo = {
				-- 			allFeatures = true,
				-- 			loadOutDirsFromCheck = true,
				-- 			runBuildScripts = true,
				-- 		},
				-- 		-- Add clippy lints for Rust.
				-- 		checkOnSave = {
				-- 			allFeatures = true,
				-- 			command = "clippy",
				-- 			extraArgs = { "--no-deps" },
				-- 		},
				-- 		procMacro = {
				-- 			enable = true,
				-- 			ignored = {
				-- 				["async-trait"] = { "async_trait" },
				-- 				["napi-derive"] = { "napi" },
				-- 				["async-recursion"] = { "async_recursion" },
				-- 			},
				-- 		},
				-- 	},
				-- },
				-- },
				taplo = {
					keys = {
						{
							"K",
							function()
								if vim.fn.expand("%:t") == "Cargo.toml" and require("crates").popup_available() then
									require("crates").show_popup()
								else
									vim.lsp.buf.hover()
								end
							end,
							desc = "Show Crate Documentation",
						},
					},
				},
				gopls = {
					settings = {
						gofumpt = true,
					},
				},
			},
		},
	},
	{
		"saecki/crates.nvim",
		event = { "BufRead Cargo.toml" },
		opts = {
			completion = {
				cmp = { enabled = false },
			},
		},
	},
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		cmd = "ConformInfo",
		keys = {
			{
				"<leader>cF",
				function()
					require("conform").format({ async = true, lsp_fallback = true, formatters = { "injected" } })
				end,
				mode = { "n", "v" },
				desc = "Format Injected Langs",
			},
		},
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				json = { "fixjson" },
				python = { "isort", "black" },
				nix = { "nixpkgs_fmt" },
				-- typescript = { "eslint_d" },
				-- typescriptreact = { "eslint_d" },
				-- typescript = { "dprint" },
				-- typescriptreact = { "dprint" },
				javascript = { "biome-check", "prettierd", "prettier", "eslint_d", stop_after_first = true },
				typescript = { "biome-check", "prettierd", "prettier", "eslint_d", stop_after_first = true },
				javascriptreact = {
					"biome-check",
					"prettierd",
					"prettier",
					"eslint_d",
					stop_after_first = true,
				},
				typescriptreact = {
					"biome-check",
					"prettierd",
					"prettier",
					"eslint_d",
					stop_after_first = true,
				},
			},
			-- Set up format-on-save
			format_on_save = { timeout_ms = 500, lsp_fallback = true },
			formatters = {
				stylua = {},
				-- prettier = {
				-- 	require_cwd = true,
				-- 	cwd = require("conform.util").root_file({
				-- 		".prettierrc.yaml",
				-- 	}),
				-- },
				-- eslint_d = {
				-- 	require_cwd = true,
				-- 	cwd = require("conform.util").root_file({
				-- 		"eslint.config.js",
				-- 		"eslint.config.cjs",
				-- 	}),
				-- },
			},
		},
	},
	-- {
	-- 	"jose-elias-alvarez/typescript.nvim",
	-- 	dependencies = "jose-elias-alvarez/null-ls.nvim",
	-- },
	{
		"pmizio/typescript-tools.nvim",
		-- event = "LspAttach",
		ft = { "typescript", "typescriptreact", "typescript.tsx" },
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		opts = {
			-- CodeLens
			-- WARNING: Experimental feature also in VSCode, because it might hit performance of server.
			-- possible values: ("off"|"all"|"implementations_only"|"references_only")
			code_lens = "all",
		},
	},
	{
		"simrat39/rust-tools.nvim",
		enabled = false,
		ft = "rust",
		dependencies = { "neovim/nvim-lspconfig" },
		opts = function()
			-- TODO: Change from mason to lazy-lsp / nix to pull info
			local ok, mason_registry = pcall(require, "mason-registry")
			local adapter ---@type any
			if ok then
				-- rust tools configuration for debugging support
				local codelldb = mason_registry.get_package("codelldb")
				local extension_path = codelldb:get_install_path() .. "/extension/"
				local codelldb_path = extension_path .. "adapter/codelldb"
				local liblldb_path = ""
				if vim.loop.os_uname().sysname:find("Windows") then
					liblldb_path = extension_path .. "lldb\\bin\\liblldb.dll"
				elseif vim.fn.has("mac") == 1 then
					liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"
				else
					liblldb_path = extension_path .. "lldb/lib/liblldb.so"
				end
				adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path)
			end
			return {
				dap = {
					adapter = adapter,
				},
				tools = {
					on_initialized = function()
						vim.cmd([[
                          augroup RustLSP
                            autocmd CursorHold                      *.rs silent! lua vim.lsp.buf.document_highlight()
                            autocmd CursorMoved,InsertEnter         *.rs silent! lua vim.lsp.buf.clear_references()
                            autocmd BufEnter,CursorHold,InsertLeave *.rs silent! lua vim.lsp.codelens.refresh()
                          augroup END
                        ]])
					end,
				},
			}
		end,
		config = function() end,
	},
	{
		"mrcjkb/rustaceanvim",
		dependencies = { "neovim/nvim-lspconfig" },
		version = "^5", -- Recommended
		lazy = false,
		ft = { "rust" },
	},
	{
		"saghen/blink.cmp",
		-- name = "blink-cmp",
		lazy = false, -- lazy loading handled internally
		-- optional: provides snippets for the snippet source
		dependencies = { "rafamadriz/friendly-snippets", { "L3MON4D3/LuaSnip", version = "v2.*" } },

		-- use a release tag to download pre-built binaries
		version = "*",

		-- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
		-- build = "cargo build --release",
		--
		keys = {
			{ "<Leader>a", vim.lsp.buf.code_action, desc = "Code actions" },
			{ "<Leader>rn", vim.lsp.buf.rename, desc = "Rename" },
			{ "K", vim.lsp.buf.hover, desc = "Hover" },
			{ "<Leader>F", vim.lsp.buf.format, desc = "Format document" },
			{ "[d", vim.diagnostic.goto_prev, desc = "Go to prev diagnostic" },
			{ "]d", vim.diagnostic.goto_next, desc = "Go to next diagnostic" },
			{ "<Leader>?", vim.diagnostic.open_float, desc = "Line Diagnostics" },
		},

		opts = {
			appearance = {
				nerd_font_variant = "mono",
			},

			-- experimental auto-brackets support
			-- accept = { auto_brackets = { enabled = true } }
			signature = { enabled = true },

			keymap = {
				preset = "enter",
				-- ['<CR>'] = { 'select_and_accept' },
			},

			fuzzy = {
				prebuilt_binaries = {
					download = false,
				},
			},

			completion = {
				ghost_text = {
					enabled = true,
				},
				documentation = {
					auto_show = true,
				},
				menu = {
					-- auto_show = function(ctx)
					-- 	return ctx.mode ~= "default"
					-- end,
					-- auto_show = false,
				},
			},

			snippets = {
				preset = "luasnip",
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			cmdline = {
				enabled = false,
			},
		},
		opts_extend = { "sources.default" },
	},
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		version = false, -- Never set this value to "*"! Never!
		enabled = false,
		opts = {
			provider = "ollama",
			ollama = {
				endpoint = "http://127.0.0.1:11434", -- Note that there is no /v1 at the end.
				model = "gemma3:4b",
			},
		},
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			{
				-- support for image pasting
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					-- recommended settings
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						drag_and_drop = {
							insert_mode = true,
						},
						-- required for Windows users
						use_absolute_path = true,
					},
				},
			},
			{
				-- Make sure to set this up properly if you have lazy=true
				"MeanderingProgrammer/render-markdown.nvim",
				opts = {
					file_types = { "markdown", "Avante" },
				},
				ft = { "markdown", "Avante" },
			},
		},
	},
}
