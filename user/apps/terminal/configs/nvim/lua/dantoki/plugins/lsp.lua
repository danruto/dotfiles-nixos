return {
	{
		"williamboman/mason.nvim",
		cmd = {
			"Mason",
			"MasonInstall",
			"MasonInstallAll",
			"MasonUninstall",
			"MasonUninstallAll",
			"MasonLog",
		},
		opts = {
			ui = {
				icons = {
					package_pending = " ",
					package_installed = " ",
					package_uninstalled = " ﮊ",
				},
				keymaps = {
					toggle_server_expand = "<CR>",
					install_server = "i",
					update_server = "u",
					check_server_version = "c",
					update_all_servers = "U",
					check_outdated_servers = "C",
					uninstall_server = "X",
					cancel_installation = "<C-c>",
				},
			},
			max_concurrent_installers = 10,
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"SmiteshP/nvim-navbuddy",
				-- event = "LspAttach",
				dependencies = {
					"neovim/nvim-lspconfig",
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
	},
	{
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local ok, mason_lspconfig, lspconfig, util, cmp_lsp = pcall(function()
				return require("mason-lspconfig"),
					require("lspconfig"),
					require("lspconfig.util"),
					require("cmp_nvim_lsp")
			end)
			if not ok then
				return
			end

			local capabilities
			do
				local default_capabilities = vim.lsp.protocol.make_client_capabilities()
				capabilities = {
					textDocument = {
						foldingRange = {
							dynamicRegistration = false,
							lineFoldingOnly = true,
						},
						completion = {
							completionItem = {
								snippetSupport = true,
							},
						},
						codeAction = {
							resolveSupport = {
								properties = vim.list_extend(
									default_capabilities.textDocument.codeAction.resolveSupport.properties,
									{
										"documentation",
										"detail",
										"additionalTextEdits",
									}
								),
							},
						},
					},
				}
			end

			util.default_config = vim.tbl_deep_extend("force", util.default_config, {
				capabilities = vim.tbl_deep_extend(
					"force",
					vim.lsp.protocol.make_client_capabilities(),
					cmp_lsp.default_capabilities(capabilities)
				),
			})

			mason_lspconfig.setup({
				ensure_installed = {
					-- "csharpls",
					-- "dartls",
					"dockerls",
					-- "eslint",
					"gopls",
					"graphql",
					"html",
					"jsonls",
					"lua_ls",
					"pyright",
					"rust_analyzer",
					"sqlls",
					"tailwindcss",
					"tsserver",
					"vuels",
					"yamlls",
					-- "omnisharp",
				},
				automatic_installation = true,
			})

			mason_lspconfig.setup_handlers({
				function(server_name)
					lspconfig[server_name].setup({})
				end,
				-- ["tsserver"] = function()
				-- 	require("typescript").setup({
				-- 		server = {
				-- 			settings = {
				-- 				typescript = {
				-- 					inlayHints = {
				-- 						includeInlayParameterNameHints = "all",
				-- 						includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				-- 						includeInlayFunctionParameterTypeHints = true,
				-- 						includeInlayVariableTypeHints = true,
				-- 						includeInlayPropertyDeclarationTypeHints = true,
				-- 						includeInlayFunctionLikeReturnTypeHints = true,
				-- 						includeInlayEnumMemberValueHints = true,
				-- 					},
				-- 				},
				-- 				javascript = {
				-- 					inlayHints = {
				-- 						includeInlayParameterNameHints = "all",
				-- 						includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				-- 						includeInlayFunctionParameterTypeHints = true,
				-- 						includeInlayVariableTypeHints = true,
				-- 						includeInlayPropertyDeclarationTypeHints = true,
				-- 						includeInlayFunctionLikeReturnTypeHints = true,
				-- 						includeInlayEnumMemberValueHints = true,
				-- 					},
				-- 				},
				-- 			},
				-- 		},
				-- 	})
				-- end,
				["rust_analyzer"] = function()
					require("rust-tools").setup({
						tools = {
							inlay_hints = { auto = false },
							executor = require("rust-tools/executors").toggleterm,
							hover_actions = { border = "solid" },
						},
						procMacro = {
							ignored = {
								["async-trait"] = { "async_trait" },
								["napi-derive"] = { "napi" },
								["async-recursion"] = { "async_recursion" },
							},
						},
						dap = {
							adapter = {
								type = "server",
								port = "${port}",
								host = "127.0.0.1",
								executable = {
									command = "codelldb",
									args = { "--port", "${port}" },
								},
							},
						},
						server = {
							on_attach = function(_, bufnr)
								local rt_ok, rt = pcall(function()
									return require("rust-tools")
								end)

								if not rt_ok then
									return
								end

								-- Add custom key maps for rt based lspconfig
								local rt_opts = { noremap = true, silent = true, buffer = bufnr }
								vim.keymap.set("n", "<C-Space>", rt.hover_actions.hover_actions, rt_opts)
								vim.keymap.set("n", "<Leader>ca", rt.code_action_group.code_action_group, rt_opts)
							end,
						},
					})
				end,
				["gopls"] = function()
					lspconfig.gopls.setup({
						settings = {
							gopls = {
								codelenses = { test = true },
								hints = {
									assignVariableTypes = true,
									compositeLiteralFields = true,
									compositeLiteralTypes = true,
									constantValues = true,
									functionTypeParameters = true,
									parameterNames = true,
									rangeVariableTypes = true,
								},
							},
						},
					})
				end,
			})
		end,
	},
	{
		"zbirenbaum/copilot.lua",
		enabled = true,
		cmd = "Copilot",
		event = "InsertEnter",
		opts = {
			suggestion = { enabled = false },
			panel = { enabled = false },
		},
	},
	{
		"saecki/crates.nvim",
		opts = {},
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
			"zbirenbaum/copilot-cmp",
			"saecki/crates.nvim",
		},
		config = function()
			require("dantoki.configs.cmp")
		end,
	},
	{
		"nvimtools/none-ls.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("dantoki.configs.null-ls")
		end,
	},
	-- {
	-- 	"jose-elias-alvarez/typescript.nvim",
	-- 	dependencies = "jose-elias-alvarez/null-ls.nvim",
	-- },
	{
		"pmizio/typescript-tools.nvim",
		event = "LspAttach",
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
		-- config = function()
		-- 	local rt = require("rust-tools")
		-- 	local tb = require("telescope.builtin")
		-- 	rt.setup({
		-- 		server = {
		-- 			on_attach = function(_, bufnr)
		-- 				-- Add custom key maps for rt based lspconfig
		-- 				local rt_opts = { noremap = true, silent = true, buffer = bufnr }
		-- 				vim.keymap.set("n", "<C-Space>", rt.hover_actions.hover_actions, rt_opts)
		-- 				vim.keymap.set("n", "<Leader>ca", rt.code_action_group.code_action_group, rt_opts)
		--
		-- 				-- Common regular lsp keys
		-- 				vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, rt_opts)
		-- 				vim.keymap.set("n", "gd", tb.lsp_definitions, rt_opts)
		-- 				vim.keymap.set("n", "gD", tb.lsp_type_definitions, rt_opts)
		-- 				vim.keymap.set("n", "gr", tb.lsp_references, rt_opts)
		-- 				vim.keymap.set("n", "gi", tb.lsp_implementations, rt_opts)
		-- 				vim.keymap.set("n", "<Leader>F", vim.lsp.buf.formatting, rt_opts)
		-- 				vim.keymap.set("n", "<Leader>S", tb.lsp_workspace_symbols, rt_opts)
		-- 				vim.keymap.set("n", "<Leader>s", tb.lsp_document_symbols, rt_opts)
		-- 				-- vim.keymap.set("n", "K", vim.lsp.buf.hover, rt_opts)
		-- 				vim.keymap.set({ "n", "v" }, "<Space>a", vim.lsp.buf.code_action, rt_opts)
		-- 			end,
		-- 		},
		-- 	})
		-- end,
	},
}
