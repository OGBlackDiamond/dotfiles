-- nvim-treesitter (main branch — required for Neovim 0.12+)

return {
    {
        "nvim-treesitter/nvim-treesitter-context",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        config = function()
            require("treesitter-context").setup({
                max_lines = 0,
                multiline_threshold = 2, -- collapse multi-line nodes to a single line
                trim_scope = "outer",
                mode = "cursor",
                separator = nil,
            })

            local ok, c = pcall(require, "nordic.colors")
            if ok then
                vim.api.nvim_set_hl(0, "TreesitterContext", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { fg = c.gray4, bg = "NONE" })
                vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true, sp = c.gray3 })
            end
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = function()
            require("nvim-treesitter").install({
                "bash",
                "c",
                "cpp",
                "go",
                "java",
                "lua",
                "markdown",
                "markdown_inline",
                "python",
                "qmljs",
                "query",
                "typescript",
                "javascript",
                "tsx",
                "vim",
                "vimdoc",
            })
        end,
    },
}
