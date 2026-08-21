local augroup = vim.api.nvim_create_augroup("user_config", { clear = true })

vim.filetype.add({
    extension = {
        qml = "qml",
    },
    pattern = {
        [".*/quickshell/.*%.qml"] = "qml",
    },
})

pcall(vim.treesitter.language.register, "qmljs", "qml")

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = {
        "PlenaryTestPopup",
        "checkhealth",
        "dbout",
        "gitsigns-blame",
        "grug-far",
        "help",
        "lspinfo",
        "neotest-output",
        "neotest-output-panel",
        "neotest-summary",
        "notify",
        "qf",
        "spectre_panel",
        "startuptime",
        "tsplayground",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.schedule(function()
            vim.keymap.set("n", "q", function()
                vim.cmd("close")
                pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
            end, {
                buffer = event.buf,
                silent = true,
                desc = "Quit buffer",
            })
        end)
    end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end,
})

-- Set filetype for .toml files
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    group = augroup,
    pattern = { "*.tomg-config*" },
    callback = function()
        vim.bo.filetype = "toml"
    end,
})

-- Fix conceallevel for json files
vim.api.nvim_create_autocmd({ "FileType" }, {
    group = augroup,
    pattern = { "json", "jsonc", "json5" },
    callback = function()
        vim.opt_local.conceallevel = 0
    end,
})

-- Attach treesitter highlighting and auto-install missing parsers
-- this is because treesitter doesn't auto-install anymore
vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    callback = function(ev)
        local ft = vim.bo[ev.buf].filetype
        local ignored_fts = { snacks_notif = true, snacks_input = true, snacks_picker = true, mason = true }
        if ft == "" or ignored_fts[ft] then
            return
        end

        local ok_ts, ts = pcall(require, "nvim-treesitter")
        local ok_cfg, cfg = pcall(require, "nvim-treesitter.config")
        if not ok_ts or not ok_cfg then
            return
        end

        local parser_by_ft = {
            qml = "qmljs",
        }
        local parser = parser_by_ft[ft] or ft
        local installed = cfg.get_installed()
        if not vim.tbl_contains(installed, parser) then
            ts.install({ parser })
        end

        -- Start highlighting; silently skip if parser unavailable
        pcall(vim.treesitter.start, ev.buf, parser)
    end,
})

-- LSP keymaps (definitions live in keymaps.lua)
vim.api.nvim_create_autocmd("LspAttach", {
    group = augroup,
    callback = function(ev)
        LspKeymaps(ev.buf)

        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end
    end,
})

-- blink.cmp can leave the signature-help active-parameter highlight visible
-- after leaving insert mode; force-close it when returning to normal mode.
vim.api.nvim_create_autocmd("InsertLeave", {
    group = augroup,
    callback = function()
        local ok, cmp = pcall(require, "blink.cmp")
        if ok then
            cmp.hide_signature()
        end
    end,
})

vim.api.nvim_create_autocmd("ModeChanged", {
    group = augroup,
    pattern = "i:n",
    callback = function()
        local ok, cmp = pcall(require, "blink.cmp")
        if ok then
            cmp.hide_signature()
        end
    end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    callback = function(event)
        local exclude = { "gitcommit" } -- don't remember position in commit messages
        local buf = event.buf
        local ft = vim.bo[buf].filetype
        if vim.tbl_contains(exclude, ft) then
            return
        end
        local mark = vim.api.nvim_buf_get_mark(buf, '"')
        local lcount = vim.api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})
