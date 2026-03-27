local opt = vim.opt
local undo_dir = vim.fn.stdpath("state") .. "/undo"

vim.fn.mkdir(undo_dir, "p")

opt.guicursor = "i:block"
opt.colorcolumn = "80"
opt.signcolumn = "yes:1"
opt.termguicolors = true
opt.ignorecase = true
opt.smartcase = true
opt.swapfile = false
opt.autoindent = true
opt.expandtab = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.shiftround = true
opt.listchars = "tab:» ,trail:·,nbsp:␣"
opt.list = true
opt.number = false
opt.relativenumber = false
opt.numberwidth = 2
opt.wrap = false
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.inccommand = "split"
opt.undodir = undo_dir
opt.undofile = true
opt.completeopt = { "menuone", "popup", "noinsert" }
opt.splitbelow = true
opt.splitright = true
opt.winborder = "rounded"
opt.hlsearch = false
opt.updatetime = 200

vim.cmd.filetype("plugin indent on")
