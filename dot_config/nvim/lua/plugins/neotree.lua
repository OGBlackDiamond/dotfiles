return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    config = function()
        require("neo-tree").setup({
            close_if_last_window = true,
            source_selector = {
                winbar = false,
                statusline = false,
            },
            filesystem = {
                filtered_items = {
                    visible = false,
                    show_hidden_count = true,
                    hide_dotfiles = false,
                    hide_gitignored = false,
                    hide_by_name = {
                        ".git",
                        -- '.DS_Store',
                        -- 'thumbs.db',
                    },
                    never_show = {},
                },
            },
            follow_current_file = {
                enabled = true,
                leave_dirs_open = true,
            }
        })
        vim.keymap.set("n", "<C-[>", ":Neotree filesystem show left<CR>", {})
        vim.keymap.set("n", "<C-]>", ":Neotree filesystem close<CR>", {})
        vim.keymap.set("n", "<C-\\>", ":Neotree filesystem focus<CR>", {})
    end,
}
