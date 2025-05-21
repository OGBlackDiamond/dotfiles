return {
    'OGBlackDiamond/transparent-nordic.nvim',
    lazy = false,
    priority = 1000,
    config = function()

        require('nordic').setup({
            on_highlight = function(highlights, palette)
                highlights.TelescopePromptTitle = {
                    fg = palette.none,
                    bg = palette.none,
                }
            end,

            transparent = {
                bg = true,
                float = true,

            },
        })

        vim.cmd.colorscheme('nordic')
    end
}
