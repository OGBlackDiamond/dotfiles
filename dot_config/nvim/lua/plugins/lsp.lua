-- LSP: mason + mason-lspconfig + nvim-lspconfig
--
-- Load order enforced by lazy.nvim dependencies:
--   mason.nvim -> nvim-lspconfig -> mason-lspconfig.nvim
--
-- Server config lives in vim.lsp.config() calls below.
-- mason-lspconfig automatically calls vim.lsp.enable() for every installed server.

-- Shared capabilities — extended by blink.cmp when it's loaded
local function make_capabilities()
    local base = vim.lsp.protocol.make_client_capabilities()
    -- blink.cmp advertises richer completion capabilities to LSP servers
    -- (labelDetails, insertReplaceSupport, snippetSupport, etc.)
    local ok, blink = pcall(require, "blink.cmp")
    if ok then
        return blink.get_lsp_capabilities(base)
    end
    return base
end

-- Called when an LSP client attaches to a buffer
local function on_attach(client, bufnr)
    -- Format on save if the server supports it (client:method() syntax required in 0.12+)
    if client:supports_method("textDocument/formatting") then
        vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.format({ bufnr = bufnr, async = false })
            end,
        })
    end
end

-- Global defaults applied to every server
vim.lsp.config("*", {
    capabilities = make_capabilities(),
    on_attach = on_attach,
})

-- Per-server configuration via vim.lsp.config (native 0.11+ API)
vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
                checkThirdParty = false,
                library = vim.api.nvim_get_runtime_file("", true),
            },
            diagnostics = { globals = { "vim" } },
            telemetry = { enable = false },
        },
    },
})

vim.lsp.config("ts_ls", {
    init_options = {
        preferences = {
            includeInlayParameterNameHints = "all",
        },
    },
})

vim.lsp.config("pyright", {
    settings = {
        python = {
            analysis = {
                typeCheckingMode = "basic",
                autoImportCompletions = true,
            },
        },
    },
})

vim.lsp.config("clangd", {
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
    },
})

vim.lsp.config("gopls", {
    settings = {
        gopls = {
            analyses = { unusedparams = true },
            staticcheck = true,
        },
    },
})

vim.lsp.config("bashls", {})



return {
    -- 1. Mason: binary installer UI
    {
        "mason-org/mason.nvim",
        build = ":MasonUpdate",
        opts = {},
    },

    -- 2. nvim-lspconfig: provides server default configs consumed by vim.lsp.config
    {
        "neovim/nvim-lspconfig",
        -- no setup() call needed; we use vim.lsp.config() above
    },

    -- 3. mason-lspconfig: bridges Mason installs -> vim.lsp.enable()
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
            "mason-org/mason.nvim",
            "neovim/nvim-lspconfig",
        },
        opts = {
            ensure_installed = {
                "lua_ls",
                "ts_ls",
                "pyright",
                "clangd",
                "gopls",
                "bashls",
                "jdtls",
            },
            -- jdtls is excluded because it requires a dynamic per-project workspace
            -- path in its cmd — it's started manually via a FileType autocmd above
            --[[
            automatic_enable = {
                exclude = { "jdtls" },
            },
            --]]
        },
    },
}
