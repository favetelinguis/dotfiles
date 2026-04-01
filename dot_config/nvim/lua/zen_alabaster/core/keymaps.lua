local map = vim.keymap.set

local function opts(desc)
  return { silent = true, desc = desc }
end

map("n", "<space>", "<Nop>", opts("Leader noop"))
map("n", "<Esc>", "<cmd>nohlsearch<cr>", opts("Clear search highlight"))

map("n", "j", function()
  return vim.v.count > 0 and "j" or "gj"
end, { expr = true, silent = true, desc = "Move down by display line" })

map("n", "k", function()
  return vim.v.count > 0 and "k" or "gk"
end, { expr = true, silent = true, desc = "Move up by display line" })

map("n", "<C-d>", "<C-d>zz", opts("Half-page down and center"))
map("n", "<C-u>", "<C-u>zz", opts("Half-page up and center"))
map("n", "<leader>w", "<cmd>write<cr>", opts("Write buffer"))
map("n", "<leader>q", "<cmd>quit<cr>", opts("Quit window"))
map("n", "<leader>sv", "<cmd>vsplit<cr>", opts("Vertical split"))
map("n", "<leader>sh", "<cmd>split<cr>", opts("Horizontal split"))
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, opts("Previous diagnostic"))
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, opts("Next diagnostic"))
map("n", "<leader>e", vim.diagnostic.open_float, opts("Line diagnostics"))
map("n", "<leader>ps", "<cmd>PackSync<cr>", opts("Install managed plugins"))
map("n", "<leader>pu", "<cmd>PackUpdate<cr>", opts("Update managed plugins"))
map("n", "<leader>ti", "<cmd>TSInstallManaged<cr>", opts("Install managed Tree-sitter parsers"))
map("n", "<leader>tu", "<cmd>TSUpdateManaged<cr>", opts("Update managed Tree-sitter parsers"))
