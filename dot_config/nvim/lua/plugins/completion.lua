-- Completion: blink.cmp v1 (stable)
-- Replaces: nvim-cmp + cmp-nvim-lsp + cmp-buffer + cmp-path + LuaSnip + cmp_luasnip
-- Uses native vim.snippet for snippet expansion (no LuaSnip needed)

return {
    {
        "saghen/blink.cmp",
        version = "1.*",                    -- pins to v1 stable; downloads pre-built binary (no Rust needed)
        dependencies = {
            "rafamadriz/friendly-snippets", -- large collection of pre-written snippets
        },
        config = function(_, opts)
            require("blink.cmp").setup(opts)

            -- Set blink highlights after setup() so they aren't overridden by blink internals
            local ok, c = pcall(require, "nordic.colors")
            if ok then
                local float_fg = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false }).fg
                local sel_bg   = vim.api.nvim_get_hl(0, { name = "PmenuSel", link = false }).bg

                -- Completion menu — transparent background (matches terminal bg)
                vim.api.nvim_set_hl(0, "BlinkCmpMenu", { fg = float_fg, bg = "NONE" })
                vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { fg = c.orange.dim, bg = "NONE" })
                vim.api.nvim_set_hl(0, "BlinkCmpMenuSelection", { bg = sel_bg })
                vim.api.nvim_set_hl(0, "PmenuKind", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "PmenuExtra", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "BlinkCmpScrollBarThumb", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "BlinkCmpScrollBarGutter", { bg = "NONE" })

                -- Documentation window — transparent background, orange text
                vim.api.nvim_set_hl(0, "BlinkCmpDoc", { fg = c.orange.base, bg = "NONE" })
                vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { fg = c.orange.dim, bg = "NONE" })
                vim.api.nvim_set_hl(0, "BlinkCmpDocSeparator", { fg = c.orange.dim, bg = "NONE" })
                vim.api.nvim_set_hl(0, "BlinkCmpDocCursorLine", { bg = sel_bg })

                -- Signature help — transparent background (matches terminal bg)
                vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelp", { fg = float_fg, bg = "NONE" })
                vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelpBorder", { fg = c.orange.dim, bg = "NONE" })
            end
        end,
        opts = {
            keymap = {
                preset = "default", -- inherit everything not overridden below
                ["<C-j>"] = { "select_next", "fallback" },
                ["<C-k>"] = { "select_prev", "fallback" },
                ["<C-p>"] = { "select_prev", "fallback" },
                ["<CR>"] = { "accept", "fallback" },
            },

            appearance = {
                nerd_font_variant = "normal",
            },

            sources = {
                default = { "lsp", "path", "snippets", "buffer" },
            },

            completion = {
                menu = {
                    -- border inherited from vim.o.winborder
                    scrollbar = false,
                    draw = {
                        padding = { 1, 1 }, -- left/right padding inside the menu
                    },
                },
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 200,
                },
                accept = {
                    auto_brackets = { enabled = true }, -- inserts () after accepting a function
                },
                ghost_text = { enabled = true },        -- inline preview of top suggestion
            },

            signature = {
                enabled = true,
                trigger = { enabled = true }, -- auto-show when cursor enters function arguments
            },

            fuzzy = {
                -- use Rust matcher when pre-built binary is available, fall back to Lua silently
                implementation = "prefer_rust",
            },
        },
    },
}
