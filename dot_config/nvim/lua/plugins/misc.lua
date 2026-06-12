return {
    -- In-editor markdown rendering (headings, code blocks, tables, etc.)
    -- snacks.nvim picker preview automatically uses this when installed
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown" },
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
