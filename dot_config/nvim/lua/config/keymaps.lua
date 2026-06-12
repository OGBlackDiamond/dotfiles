local map = vim.keymap.set

vim.g.mapleader = " "

map("n", "<leader><Tab>", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader><S-Tab>", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })

map("n", "<leader>t", ":vsplit<CR>", { desc = "Vertical Split" })
map("n", "<leader>T", ":10split<CR><C-w>j:term<CR>i", { desc = "Terminal Split" })

-- Auto closing pairs
map("i", "`", "``<left>")
map("i", '"', '""<left>')
map("i", "(", "()<left>")
map("i", "[", "[]<left>")
map("i", "{", "{}<left>")
map("i", "<", "<><left>")
map("i", "'", "''<left>")

map("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })

map("n", "<leader>j", vim.diagnostic.open_float, { desc = "Line Diagnostics" })

-- Called from the LspAttach autocmd in autocmds.lua
function LspKeymaps(bufnr)
    local lmap = function(keys, func, desc)
        vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
    end
    lmap("gd", vim.lsp.buf.definition, "Go to Definition")
    lmap("gD", vim.lsp.buf.declaration, "Go to Declaration")
    lmap("gri", vim.lsp.buf.implementation, "Go to Implementation")
    lmap("grr", vim.lsp.buf.references, "References")
    lmap("grt", vim.lsp.buf.type_definition, "Go to Type Definition")
    lmap("grx", vim.lsp.codelens.run, "Run Codelens")
    lmap("<leader>ca", vim.lsp.buf.code_action, "Code Action")
    lmap("<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
    lmap("<leader>f", function() vim.lsp.buf.format({ async = true }) end, "Format Buffer")
    lmap("<leader>k", vim.lsp.buf.hover, "Hover Docs")
end
