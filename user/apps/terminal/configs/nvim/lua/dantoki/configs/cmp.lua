local ok, cmp = pcall(require, "cmp")

if not ok then
	return
end

local lspkind = require("lspkind")

vim.opt.completeopt = "menuone,noselect"

local function border(hl_name)
	return {
		{ "╭", hl_name },
		{ "─", hl_name },
		{ "╮", hl_name },
		{ "│", hl_name },
		{ "╯", hl_name },
		{ "─", hl_name },
		{ "╰", hl_name },
		{ "│", hl_name },
	}
end

local function has_words_before()
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

-- local cmp_window = require("cmp.utils.window")
-- cmp_window.info_ = cmp_window.info
-- cmp_window.info = function(self)
-- 	local info = self:info_()
-- 	info.scrollable = false
-- 	return info
-- end

-- vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
local options = {
	-- window = {
	-- 	completion = {
	-- 		border = border("CmpBorder"),
	-- 		winhighlight = "Normal:CmpPmenu,CursorLine:PmenuSel,Search:None",
	-- 	},
	-- 	documentation = {
	-- 		border = border("CmpDocBorder"),
	-- 	},
	-- },
	completion = {
		completeopt = "menuone,noinsert",
	},
	window = {
		completion = cmp.config.window.bordered({
			winhighlight = "Normal:Pmenu,FloatBorder:PmenuBorder,CursorLine:PmenuSel,Search:None",
			scrollbar = true,
			col_offset = -1,
			side_padding = 0,
		}),
		documentation = cmp.config.window.bordered({
			winhighlight = "Normal:Pmenu,FloatBorder:PmenuDocBorder,CursorLine:PmenuSel,Search:None",
			scrollbar = true,
		}),
	},
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	mapping = {
		["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
		["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Replace,
			select = false,
		}),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif require("luasnip").expand_or_jumpable() then
				vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
			elseif has_words_before() then
				cmp.complete()
			else
				fallback()
			end
		end, {
			"i",
			"s",
		}),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif require("luasnip").jumpable(-1) then
				vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
			else
				fallback()
			end
		end, {
			"i",
			"s",
		}),
		-- experimental = {
		-- 	ghost_text = {
		-- 		hl_group = "CmpGhostText",
		-- 	},
		-- },
	},
	sources = {
		{ name = "nvim_lsp_signature_help", priority = 1000 },
		{ name = "nvim_lsp", priority = 900 },
		{ name = "luasnip", priority = 800 },
		-- { name = "copilot", priority = 700 },
		{ name = "codeium", priority = 601 },
		{ name = "buffer", priority = 600 },
		{ name = "nvim_lua", priority = 500 },
		{ name = "path", priority = 400 },
		-- { name = "orgmode" },
		{ name = "crates", priority = 300 },
	},
	formatting = {
		format = lspkind.cmp_format({
			mode = "symbol_text", -- show only symbol annotations
			maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
			ellipsis_char = "...", -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
			-- The function below will be called before any actual modifications from lspkind
			-- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
			before = function(_entry, vim_item)
				return vim_item
			end,
		}),
	},
}

cmp.setup(options)
