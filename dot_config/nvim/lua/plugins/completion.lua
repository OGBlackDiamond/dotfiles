-- Completion: blink.cmp v1 (stable)
-- Replaces: nvim-cmp + cmp-nvim-lsp + cmp-buffer + cmp-path + cmp_luasnip
-- Uses LuaSnip for snippet expansion/navigation to avoid native vim.snippet placeholder quirks.

local function completion_visible_in_context()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local ts_col = math.max(col - 1, 0)

    local ok_captures, captures = pcall(vim.treesitter.get_captures_at_pos, 0, row - 1, ts_col)
    if ok_captures then
        for _, capture in ipairs(captures) do
            if capture.capture:find("comment") or capture.capture:find("string") then
                return false
            end
        end
    end

    local ok_node, node = pcall(vim.treesitter.get_node, { pos = { row - 1, ts_col } })
    while ok_node and node do
        local node_type = node:type()
        if node_type:find("comment") or node_type:find("string") then
            return false
        end
        node = node:parent()
    end

    local syntax_col = math.max(col, 1)
    local syntax_group = vim.fn.synIDattr(vim.fn.synID(row, syntax_col, true), "name"):lower()
    return syntax_group:find("comment") == nil and syntax_group:find("string") == nil
end

return {
    {
        "saghen/blink.cmp",
        version = "1.*",                    -- pins to v1 stable; downloads pre-built binary (no Rust needed)
        dependencies = {
            { "L3MON4D3/LuaSnip", version = "v2.*" },
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

            snippets = {
                preset = "luasnip",
            },

            sources = {
                default = { "lsp", "path", "snippets" },
            },

            completion = {
                menu = {
                    auto_show = function()
                        return completion_visible_in_context()
                    end,
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
                ghost_text = {
                    enabled = function()
                        return completion_visible_in_context()
                    end,
                }, -- inline preview of top suggestion
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
