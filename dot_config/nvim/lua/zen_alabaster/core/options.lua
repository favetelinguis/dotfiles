local opt = vim.opt
local undo_dir = vim.fs.joinpath(vim.fn.stdpath("state"), "undo")

if vim.uv.fs_stat(undo_dir) == nil then
  vim.fn.mkdir(undo_dir, "p")
end

opt.termguicolors = true
opt.number = false
opt.relativenumber = false
opt.signcolumn = "yes"
opt.cursorline = true
opt.wrap = false
opt.linebreak = true
opt.scrolloff = 6
opt.sidescrolloff = 6
opt.ignorecase = true
opt.smartcase = true
opt.expandtab = true
opt.shiftwidth = 4
opt.softtabstop = 4
opt.tabstop = 4
opt.shiftround = true
opt.smartindent = true
opt.splitbelow = true
opt.splitright = true
opt.updatetime = 200
opt.timeoutlen = 400
opt.completeopt = { "menu", "menuone", "popup", "noinsert" }
opt.winborder = "rounded"
opt.undofile = true
opt.undodir = undo_dir
opt.swapfile = false
opt.backup = false
opt.confirm = true
opt.list = true
opt.listchars = { tab = "> ", trail = ".", nbsp = "+" }
opt.laststatus = 3
opt.pumheight = 12
opt.colorcolumn = "100"
opt.statusline = "%<%f %h%m%r%=%{&filetype == '' ? 'text' : &filetype} %l:%c %L"
