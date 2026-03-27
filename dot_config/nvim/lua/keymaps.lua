local map = vim.keymap.set

local function with_desc(desc)
    return { silent = true, desc = desc }
end

map("n", "<space>", "<Nop>", with_desc("Leader noop"))

map("n", "j", function()
    return vim.v.count > 0 and "j" or "gj"
end, { expr = true, silent = true, desc = "Move down by display line" })

map("n", "k", function()
    return vim.v.count > 0 and "k" or "gk"
end, { expr = true, silent = true, desc = "Move up by display line" })

map("n", "<C-d>", "<C-d>zz", with_desc("Half-page down and center"))
map("n", "<C-u>", "<C-u>zz", with_desc("Half-page up and center"))
map("n", "<leader>w", "<cmd>write<cr>", with_desc("Write buffer"))
map("n", "<leader>q", "<cmd>quit<cr>", with_desc("Quit window"))
map("n", "<leader>te", "<cmd>tabnew<cr>", with_desc("Open new tab"))
map("n", "<leader>_", "<cmd>vsplit<cr>", with_desc("Vertical split"))
map("n", "<leader>-", "<cmd>split<cr>", with_desc("Horizontal split"))
map("v", "<leader>p", '"_dP', with_desc("Paste without yanking replaced text"))
map("x", "y", [["+y]], with_desc("Yank to system clipboard"))
map("t", "<Esc>", "<C-\\><C-n>", with_desc("Leave terminal mode"))

map("n", "<leader>cd", function()
    vim.cmd.lcd(vim.fn.expand("%:p:h"))
end, with_desc("Change local cwd to current file"))

map("n", "<leader>pu", function()
    vim.pack.update()
end, with_desc("Update vim.pack plugins"))

map("n", "<leader>gs", "<cmd>Git<cr>", with_desc("Git status"))
map("n", "<leader>gp", "<cmd>Git push<cr>", with_desc("Git push"))

map("n", "<leader>oo", "<cmd>Octo<cr>", with_desc("Octo actions"))
map("n", "<leader>op", "<cmd>Octo pr list<cr>", with_desc("List pull requests"))
map("n", "<leader>oi", "<cmd>Octo issue list<cr>", with_desc("List issues"))
map("n", "<leader>od", "<cmd>Octo discussion list<cr>", with_desc("List discussions"))
map("n", "<leader>on", "<cmd>Octo notification list<cr>", with_desc("List notifications"))
map("n", "<leader>or", "<cmd>Octo repo view<cr>", with_desc("View current repository"))
map("n", "<leader>os", function()
    local ok, utils = pcall(require, "octo.utils")
    if ok then
        utils.create_base_search_command({ include_current_repo = true })
    else
        vim.notify("octo.nvim is not installed yet", vim.log.levels.WARN)
    end
end, with_desc("Search GitHub"))
