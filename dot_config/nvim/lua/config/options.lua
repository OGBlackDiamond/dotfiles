local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = false
opt.wrap = false
opt.scrolloff = 10
opt.sidescrolloff = 8

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- Visual
opt.termguicolors = true
opt.signcolumn = "yes"
opt.showmatch = true
opt.matchtime = 2
opt.cmdheight = 1
opt.showmode = true
opt.pumheight = 10
opt.pumblend = 10
opt.winblend = 0
opt.winborder = "rounded"
opt.completeopt = "menu,menuone,noselect"
opt.conceallevel = 2
opt.concealcursor = ""
opt.confirm = false
opt.synmaxcol = 300
opt.ruler = false
opt.virtualedit = "block"
opt.winminwidth = 5
opt.equalalways = false

-- File handling
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undolevels = 10000
opt.undodir = vim.fn.expand("~/.vim/undodir")
opt.updatetime = 300
opt.timeoutlen = vim.g.vscode and 1000 or 300
opt.ttimeoutlen = 0
opt.autoread = true
opt.autowrite = false

-- Behavior
opt.backspace = "indent,eol,start"
opt.autochdir = false
opt.iskeyword:append("-")
opt.path:append("**")
opt.selection = "exclusive"
opt.mouse = "a"
opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"
opt.modifiable = true

-- Folding
opt.smoothscroll = true
vim.wo.foldmethod = "expr"
opt.foldlevel = 99
opt.formatoptions = "jcroqlnt"
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"

-- Splits
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"

-- Wildmenu
opt.wildmenu = true
opt.wildmode = "longest:full,full"
opt.wildignore:append({ "*.o", "*.obj", "*.pyc", "*.class", "*.jar" })

-- Diff
opt.diffopt:append("linematch:60")

-- Performance
opt.redrawtime = 10000
opt.maxmempattern = 20000

-- Create undo directory if it doesn't exist
local undodir = vim.fn.expand("~/.vim/undodir")
if vim.fn.isdirectory(undodir) == 0 then
    vim.fn.mkdir(undodir, "p")
end

opt.fillchars = {
    fold = " ",
    foldsep = " ",
    diff = "╱",
    eob = " ",
}

opt.jumpoptions = "view"
opt.laststatus = 2 -- per-window statusline (required for inactive_sections to render)
opt.linebreak = true
opt.list = true
opt.shiftround = true
opt.shortmess:append({ W = true, I = true, c = true, C = true })

vim.g.autoformat = false
vim.g.markdown_recommended_style = 0
