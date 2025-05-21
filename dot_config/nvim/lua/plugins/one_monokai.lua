return {}
--[[
return {
	"cpea2506/one_monokai.nvim",
	lazy = false,
	name = "one_monokai",
	priority = 1000,
	config = function()
		-- start and bind theme
		require("one_monokai").setup({
			transparent = true,
			colors = {},
			italics = true,
		})
		vim.cmd.colorscheme("one_monokai")
	end,
}
--]]
