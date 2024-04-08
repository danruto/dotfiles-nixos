return {
	{
		"dundalek/lazy-lsp.nvim",
		event = "InsertEnter",
		dependencies = {
			{
				"neovim/nvim-lspconfig",
				-- "SmiteshP/nvim-navbuddy",
				-- event = "LspAttach",
				-- dependencies = {
				-- "SmiteshP/nvim-navic",
				-- "MunifTanjim/nui.nvim",
				-- },
				-- opts = {
				-- 	window = {
				-- 		border = "double",
				-- 	},
				-- 	lsp = { auto_attach = true },
				-- },
			},
		},
		opts = {
			excluded_servers = { "sqls", "rust_analyzer", "denols", "flow", "nixd", "tsserver" },
			preferred_servers = {
				python = { "pyright", "ruff_lsp" },
				rust = { "rust_analyzer" },
				-- nix = { "nil" },
				javascript = {},
				javascriptreact = {},
				["javascript.tsx"] = {},
				typescript = {},
				typescriptreact = {},
				["typescript.tsx"] = {},
				-- typescript = { "typescript-tools" },
				-- ["typescript.tsx"] = { "typescript-tools" },
				-- typescriptreact = { "typescript-tools" },
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
		version = false,
		keys = {
			{ "<Leader>a",  vim.lsp.buf.code_action,   desc = "Code actions" },
			{ "<Leader>rn", vim.lsp.buf.rename,        desc = "Rename" },
			{ "K",          vim.lsp.buf.hover,         desc = "Hover" },
			{ "<Leader>F",  vim.lsp.buf.format,        desc = "Format document" },
			{ "[d",         vim.diagnostic.goto_prev,  desc = "Go to prev diagnostic" },
			{ "]d",         vim.diagnostic.goto_next,  desc = "Go to next diagnostic" },
			{ "<Leader>?",  vim.diagnostic.open_float, desc = "Line Diagnostics" },
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
		-- config = function()
		-- 	require("dantoki.configs.cmp")
		-- end,
		opts = function()
			vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
			local cmp = require("cmp")
			local defaults = require("cmp.config.default")()
			local lspkind = require("lspkind")

			local bufIsBig = function(bufnr)
				local max_filesize = 100 * 1024 -- 100 KB
				local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
				if ok and stats and stats.size > max_filesize then
					return true
				else
					return false
				end
			end
			-- default sources for all buffers
			local default_cmp_sources = cmp.config.sources({
				{ name = "nvim_lsp_signature_help", priority = 1000 },
				{ name = "nvim_lsp",                priority = 900 },
				{ name = "luasnip",                 priority = 800 },
			}, {
				-- { name = "copilot", priority = 700 },
				{ name = "codeium",  priority = 601 },
				{ name = "buffer",   priority = 600 },
				{ name = "nvim_lua", priority = 500 },
				{ name = "path",     priority = 400 },
				-- { name = "orgmode" },
				{ name = "crates",   priority = 300 },
			})
			-- If a file is too large, I don't want to add to it's cmp sources treesitter, see:
			-- https://github.com/hrsh7th/nvim-cmp/issues/1522
			vim.api.nvim_create_autocmd("BufReadPre", {
				callback = function(t)
					local sources = default_cmp_sources
					if not bufIsBig(t.buf) then
						sources[#sources + 1] = { name = "treesitter", group_index = 2 }
					end
					cmp.setup.buffer({
						sources = sources,
					})
				end,
			})

			local has_words_before = function()
				local line, col = (unpack or table.unpack)(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
						and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			end

			local feedkey = function(key, mode)
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
			end

			local icons = {
				misc = {
					dots = "󰇘",
				},
				dap = {
					Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
					Breakpoint = " ",
					BreakpointCondition = " ",
					BreakpointRejected = { " ", "DiagnosticError" },
					LogPoint = ".>",
				},
				diagnostics = {
					Error = " ",
					Warn = " ",
					Hint = " ",
					Info = " ",
				},
				git = {
					added = " ",
					modified = " ",
					removed = " ",
				},
				kinds = {
					Array = " ",
					Boolean = "󰨙 ",
					Class = " ",
					Codeium = "󰘦 ",
					Color = " ",
					Control = " ",
					Collapsed = " ",
					Constant = "󰏿 ",
					Constructor = " ",
					Copilot = " ",
					Enum = " ",
					EnumMember = " ",
					Event = " ",
					Field = " ",
					File = " ",
					Folder = " ",
					Function = "󰊕 ",
					Interface = " ",
					Key = " ",
					Keyword = " ",
					Method = "󰊕 ",
					Module = " ",
					Namespace = "󰦮 ",
					Null = " ",
					Number = "󰎠 ",
					Object = " ",
					Operator = " ",
					Package = " ",
					Property = " ",
					Reference = " ",
					Snippet = " ",
					String = " ",
					Struct = "󰆼 ",
					TabNine = "󰏚 ",
					Text = " ",
					TypeParameter = " ",
					Unit = " ",
					Value = " ",
					Variable = "󰀫 ",
				},
			}

			return {
				completion = {
					completeopt = "menu,menuone,noinsert",
				},
				window = {
					-- completion = cmp.config.window.bordered({
					-- 	winhighlight = "Normal:Pmenu,FloatBorder:PmenuBorder,CursorLine:PmenuSel,Search:None",
					-- 	-- winhighlight = "Normal:CmpPmenu,FloatBorder:PmenuBorder,CursorLine:CmpSel,Search:PmenuSel,Search:None",
					-- 	scrollbar = true,
					-- 	col_offset = -1,
					-- 	side_padding = 0,
					-- }),
					-- documentation = cmp.config.window.bordered({
					-- 	winhighlight = "Normal:Pmenu,FloatBorder:PmenuDocBorder,CursorLine:PmenuSel,Search:None",
					-- 	-- winhighlight = "Normal:CmpPmenu,FloatBorder:PmenuBorder,CursorLine:CmpSel,Search:PmenuSel,Search:None",
					-- 	scrollbar = true,
					-- }),
				},
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
					["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
					["<S-CR>"] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					}), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
					["<C-CR>"] = function(fallback)
						cmp.abort()
						fallback()
					end,
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif require("luasnip").expand_or_jumpable() then
							feedkey("<Plug>(luasnip-expand-or-jump)", "")
						elseif has_words_before() then
							cmp.complete()
						else
							fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function()
						if cmp.visible() then
							cmp.select_prev_item()
						elseif require("luasnip").jumpable(-1) then
							feedkey("<Plug>(luasnip-jump-prev)", "")
						end
					end, { "i", "s" }),
				}),
				experimental = {
					ghost_text = {
						hl_group = "CmpGhostText",
					},
				},
				sorting = defaults.sorting,
				sources = default_cmp_sources,
				formatting = {
					format = lspkind.cmp_format({
						mode = "text_symbol", -- show only symbol annotations
						maxwidth = 50,   -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
						ellipsis_char = "...", -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
						-- The function below will be called before any actual modifications from lspkind
						-- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
						before = function(_entry, vim_item)
							return vim_item
						end,
						show_labelDetails = true, -- show labelDetails in menu. Disabled by default
					}),
				},
			}
		end,
		---@param opts cmp.ConfigSchema
		config = function(_, opts)
			for _, source in ipairs(opts.sources) do
				source.group_index = source.group_index or 1
			end
			require("cmp").setup(opts)
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
		version = "^4", -- Recommended
		ft = { "rust" },
	},
}
