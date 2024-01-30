local g = vim.g
local o = vim.o
local bo = vim.bo
local wo = vim.wo

-- use filetype.lua instead of filetype.vim. it's enabled by default in neovim 0.8 (nightly)
if vim.version().minor < 8 then
	g.did_load_filetypes = 0
	g.do_filetype_lua = 1
end

o.cul = true -- cursor line
o.mouse = "nv" -- Enable mouse
o.softtabstop = 4 -- 4 Spaces per tab
o.tabstop = 4 -- 4 Spaces per tab
o.shiftwidth = 4 -- 4 Spaces per tab
o.smarttab = true -- Makes tabbing smarter. Will use 4 vs 2
o.expandtab = true -- Converts tabs to spaces
o.cmdheight = 1

-- Buffer settings
bo.swapfile = false
bo.smartindent = true
bo.autoindent = true -- Keep indent style
bo.iskeyword = "-"
bo.formatoptions = bo.formatoptions:gsub("[cro]", "")
-- TODO: How to do this via lua?
vim.cmd([[ autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o ]])

-- Window settings
wo.relativenumber = true -- Show line numbers as relative
wo.number = true -- Show line numbers
wo.wrap = false -- Disable line wrap
wo.cursorline = true -- Highlight current line
wo.foldmethod = "marker"

vim.g.python_2_host_prog = "/usr/bin/python"
if vim.g.os == "mac" or vim.loop.os_uname().sysname == "Darwin" then
	vim.g.python3_host_prog = "/usr/local/bin/python3"

	vim.g.clipboard = {
		name = "macOS-clipboard",
		copy = { ["+"] = "pbcopy", ["*"] = "pbcopy" },
		paste = { ["+"] = "pbpaste", ["*"] = "pbpaste" },
		cache_enabled = 0,
	}
else
	vim.g.python3_host_prog = "/usr/bin/python3"
end

-- set shada path
vim.schedule(function()
	vim.opt.shadafile = vim.fn.stdpath(vim.version().minor > 7 and "state" or "data") .. "/shada/main.shada"
	vim.cmd([[ silent! rsh ]])
end)
