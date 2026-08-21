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

vim.lsp.config("qmlls", {
    cmd = { "/usr/lib/qt6/bin/qmlls" },
    filetypes = { "qml" },
    root_markers = { ".qmlls.ini", "shell.qml" },
    cmd_env = {
        QML2_IMPORT_PATH = "/usr/lib/qt6/qml",
        QML_IMPORT_PATH = "/usr/lib/qt6/qml",
    },
})

if vim.fn.executable("/usr/lib/qt6/bin/qmlls") == 1 then
    vim.lsp.enable("qmlls")
end

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

-- jdtls: override cmd to use the Mason-installed wrapper.
-- The built-in lspconfig config handles per-project -data workspace dirs
-- automatically via its cmd function, so no FileType autocmd is needed.
-- signatureHelp must be explicitly enabled in settings or jdtls returns empty signatures.
vim.lsp.config("jdtls", {
    cmd = { vim.fn.expand("~/.local/share/nvim/mason/bin/jdtls") },
    settings = {
        java = {
            signatureHelp = { enabled = true },
        },
    },
})

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

        },
    },
}
