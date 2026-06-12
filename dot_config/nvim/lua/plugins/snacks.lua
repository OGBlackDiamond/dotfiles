return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
        dashboard = {
            enabled = true,
            wo = { cursorline = false },
            keys = {
                { key = "<Tab>",   action = "down" },
                { key = "<S-Tab>", action = "up" },
            },
            preset = {
                keys = {
                    { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files()" },
                    { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.picker.grep()" },
                    { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
                    { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })" },
                    { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
                    { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                },
            },
        },
        indent = {
            enabled = true,
            indent = { char = "▏" }, -- match your old indent-blankline character
        },
        input = { enabled = true },
        notifier = { enabled = true },
        statuscolumn = { enabled = true },
        picker = { enabled = true },
    },
    keys = {
        { "<C-p>",      function() Snacks.picker.files({ hidden = true }) end, desc = "Find Files" },
        { "<leader>p",  function() Snacks.picker.grep() end,                   desc = "Live Grep" },
        { "<leader>cs", function() Snacks.picker.lsp_symbols() end,            desc = "LSP Symbols" },
    },
}
