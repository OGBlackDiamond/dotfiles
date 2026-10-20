return {
    -- LaTeX editing, compilation, and PDF-viewer integration. VimTeX must not
    -- be lazy-loaded: inverse search relies on its global command.
    {
        "lervag/vimtex",
        lazy = false,
        init = function()
            vim.g.vimtex_view_method = "sioyek"
        end,
    },

    -- In-editor markdown rendering (headings, code blocks, tables, etc.)
    -- snacks.nvim picker preview automatically uses this when installed
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown" },
        opts = {},
    },

    -- Live Markdown preview in the default browser with synchronized scrolling.
    {
        "iamcco/markdown-preview.nvim",
        ft = { "markdown" },
        cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
        build = "cd app && npx --yes yarn install",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        keys = {
            { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Toggle Markdown Preview" },
        },
    },

    -- Paired delimiters without custom mappings that interfere with bit shifts.
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {},
    },

    -- Surround text objects with delimiters, tags, or quotes.
    {
        "kylechui/nvim-surround",
        version = "*",
        event = "VeryLazy",
        opts = {},
    },

    -- Wakatime: automatic time tracking
    {
        "wakatime/vim-wakatime",
        lazy = false,
        opts = {
            status_bar_enabled = false,
        }
    },

    -- Discord Rich Presence (replaces andweeb/presence.nvim)
    -- Downloads a pre-built server binary automatically on first load
    {
        "vyfor/cord.nvim",
        lazy = false,
        build = ":Cord update fetch",
        opts = {
            text = {
                workspace      = function(opts) return "Working on: " .. opts.workspace end,
                editing        = function(opts) return "Editing: " .. opts.filename end,
                viewing        = function(opts) return "Viewing: " .. opts.filename end,
                file_browser   = function(opts) return "Browsing: " .. opts.name end,
                plugin_manager = function(opts) return "Managing plugins in: " .. opts.name end,
                lsp            = function(opts) return "Configuring LSP in: " .. opts.name end,
                docs           = function(opts) return "Reading: " .. opts.name end,
                terminal       = function(opts) return "Running commands in: " .. opts.name end,
            },
            buttons = {
                {
                    label = "Github",
                    url   = "https://github.com/OGBlackDiamond",
                },
            },
        },
    },
}
