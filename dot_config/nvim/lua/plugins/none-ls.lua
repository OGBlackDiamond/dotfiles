return {
	"nvimtools/none-ls.nvim",
	config = function()
		local null_ls = require("null-ls")
		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua,
                null_ls.builtins.formatting.isort,
                null_ls.builtins.formatting.black,
				-- null_ls.builtins.diagnostics.pylint,
				null_ls.builtins.diagnostics.checkstyle.with({
                    extra_args = { "-c", "/home/caden/dev/formatting.xml"}
                }),
                null_ls.builtins.diagnostics.trivy,
			},
		})

		vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, {})
	end,
}
