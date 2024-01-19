local present, null_ls = pcall(require, "null-ls")

if not present then
	return
end

local sources = {
	-- Git Signs
	null_ls.builtins.code_actions.gitsigns,

	-- Completions
	-- null_ls.builtins.completion.luasnip,
	null_ls.builtins.completion.spell,

	-- Code Actions
	null_ls.builtins.code_actions.eslint_d,

	-- Formatters
	null_ls.builtins.formatting.dart_format,
	-- null_ls.builtins.formatting.eslint,
	null_ls.builtins.formatting.fish_indent,
	null_ls.builtins.formatting.fixjson,
	-- null_ls.builtins.formatting.golines,
	-- null_ls.builtins.formatting.goimports,
	null_ls.builtins.formatting.gofmt,
	-- null_ls.builtins.formatting.gofumpt,
	-- null_ls.builtins.formatting.prettier,
	-- null_ls.builtins.formatting.prettierd,
	null_ls.builtins.formatting.rustfmt.with({
		extra_args = function(params)
			local Path = require("plenary.path")
			local cargo_toml = Path:new(params.root .. "/" .. "Cargo.toml")

			if cargo_toml:exists() and cargo_toml:is_file() then
				for _, line in ipairs(cargo_toml:readlines()) do
					local edition = line:match([[^edition%s*=%s*%"(%d+)%"]])
					if edition then
						return { "--edition=" .. edition }
					end
				end
			end
			-- default edition when we don't find `Cargo.toml` or the `edition` in it.
			return { "--edition=2021" }
		end,
	}),
	null_ls.builtins.formatting.stylua,
	null_ls.builtins.formatting.prettier_d_slim,
	-- function()
	-- 	local u = require("null-ls.utils").make_conditional_utils()
	--
	-- 	local has_eslint = u.root_has_file(".eslintrc.json")
	-- 		or u.root_has_file(".eslintrc.yaml")
	-- 		or u.root_has_file(".eslintrc.yml")
	--
	-- 	if has_eslint then
	-- 		return null_ls.builtins.formatting.eslint_d
	-- 	else
	-- 		return null_ls.builtins.formatting.prettier_d_slim
	-- 	end
	-- end,

	-- Diagnostics
	-- null_ls.builtins.diagnostics.eslint,
	null_ls.builtins.diagnostics.eslint_d.with({
		condition = function(utils)
			return utils.root_has_file({ ".eslintrc", ".eslintrc.yml", ".eslintrc.yaml", ".eslintrc.json" })
		end,
	}),
	null_ls.builtins.diagnostics.flake8,
	null_ls.builtins.diagnostics.stylelint,
}

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local on_attach = function(client, bufnr)
	if client.supports_method("textDocument/formatting") then
		vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = augroup,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.format({
					bufnr = bufnr,
					filter = function(c)
						return c.name == "null-ls"
					end,
				})
			end,
		})
	end
end

null_ls.setup({
	debug = true,
	sources = sources,
	on_attach = on_attach,
})
