-- Set shell to bash when on mac since fish is too slow
vim.cmd([[
if has('mac')
    set shell=/bin/bash\ -l
end
]])

-- Change G to ge
vim.keymap.set("n", "ge", "G")

-- Change $ to gl
vim.keymap.set("n", "gl", "$")

-- Change 0 to gh
vim.keymap.set("n", "gh", "0")

-- copy to system clipboard
vim.keymap.set("v", "<C-c>", '"+y')
-- better yank behaviour
vim.keymap.set("n", "Y", "y$")
