-- nvim options and keybindings
vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set number")
vim.cmd("set relativenumber")
vim.cmd("set smartindent")
vim.cmd("set splitbelow")
vim.cmd("set shell=zsh")
vim.cmd("set nowrap")

vim.g.mapleader = " "

vim.keymap.set("n", "<leader>wq", ":wa<CR>:qa<CR>", {})
vim.keymap.set("n", "<leader>t", ":vsplit<CR>")

vim.keymap.set("n", "<leader>Z", "<C-w>s<C-w>T")

-- raw terminal functionality
vim.keymap.set("n", "<leader>T", ":10split<CR><C-w>j:terminal<CR>i")
vim.keymap.set('t', '<leader>Q', "<C-\\><C-n><C-w>k",{silent = true})

vim.keymap.set("n", "<leader>j", vim.diagnostic.open_float)
