return {
	{
		"dundalek/lazy-lsp.nvim",
		dependencies = {
			{
				"neovim/nvim-lspconfig",
				"SmiteshP/nvim-navbuddy",
				-- event = "LspAttach",
				dependencies = {
					"SmiteshP/nvim-navic",
					"MunifTanjim/nui.nvim",
				},
				opts = {
					window = {
						border = "double",
					},
					lsp = { auto_attach = true },
				},
			},
		},
		opts = {
			excluded_servers = { "sqls" },
			configs = {
				rust_analyzer = {
					keys = {
						{ "K", "<cmd>RustHoverActions<cr>", desc = "Hover Actions (Rust)" },
						{ "<leader>cR", "<cmd>RustCodeAction<cr>", desc = "Code Action (Rust)" },
						{ "<leader>dr", "<cmd>RustDebuggables<cr>", desc = "Run Debuggables (Rust)" },
					},
					settings = {
						["rust-analyzer"] = {
							cargo = {
								allFeatures = true,
								loadOutDirsFromCheck = true,
								runBuildScripts = true,
							},
							-- Add clippy lints for Rust.
							checkOnSave = {
								allFeatures = true,
								command = "clippy",
								extraArgs = { "--no-deps" },
							},
							procMacro = {
								enable = true,
								ignored = {
									["async-trait"] = { "async_trait" },
									["napi-derive"] = { "napi" },
									["async-recursion"] = { "async_recursion" },
								},
							},
						},
					},
				},
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
			},
		},
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
		"saecki/crates.nvim",
		event = { "BufRead Cargo.toml" },
		opts = {
			src = {
				cmp = { enabled = true },
			},
		},
	},
	{
		"hrsh7th/nvim-cmp",
		keys = {
			{ "<Leader>a", vim.lsp.buf.code_action, desc = "Code actions" },
			{ "<Leader>rn", vim.lsp.buf.rename, desc = "Rename" },
			{ "K", vim.lsp.buf.hover, desc = "Hover" },
			{ "<Leader>F", vim.lsp.buf.format, desc = "Format document" },
			{ "[d", vim.diagnostic.goto_prev, desc = "Go to prev diagnostic" },
			{ "]d", vim.diagnostic.goto_next, desc = "Go to next diagnostic" },
			{ "<Leader>?", vim.diagnostic.open_float, desc = "Line Diagnostics" },
		},
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-nvim-lsp",
			"onsails/lspkind.nvim",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lua",
			"saadparwaiz1/cmp_luasnip",
			"lukas-reineke/cmp-under-comparator",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp-document-symbol",
			-- "zbirenbaum/copilot-cmp",
			"saecki/crates.nvim",
		},
		config = function()
			require("dantoki.configs.cmp")
		end,
	},
	{
		"nvimtools/none-ls.nvim",
		enabled = false,
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("dantoki.configs.null-ls")
		end,
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
			},
			-- Set up format-on-save
			format_on_save = { timeout_ms = 500, lsp_fallback = true },
			formatters = {
				stylua = {},
			},
		},
	},
	-- {
	-- 	"jose-elias-alvarez/typescript.nvim",
	-- 	dependencies = "jose-elias-alvarez/null-ls.nvim",
	-- },
	{
		"pmizio/typescript-tools.nvim",
		event = "LspAttach",
		ft = { "typescript", "typescriptreact" },
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
		ft = "rust",
		dependencies = { "neovim/nvim-lspconfig" },
		opts = function()
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
}
