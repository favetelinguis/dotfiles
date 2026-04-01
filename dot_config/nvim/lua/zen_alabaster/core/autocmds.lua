local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

autocmd("TextYankPost", {
  group = augroup("ZenAlabasterYank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ timeout = 180 })
  end,
})

autocmd("FileType", {
  group = augroup("ZenAlabasterProse", { clear = true }),
  pattern = { "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = true
  end,
})
