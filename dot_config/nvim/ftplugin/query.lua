local ftplugin = require("zen_alabaster.ftplugin")

if vim.b.did_ftplugin == 1 then
  return
end

ftplugin.safe_treesitter_start()

vim.bo.omnifunc = "v:lua.vim.treesitter.query.omnifunc"
vim.opt_local.iskeyword:append(".")

local buf = vim.api.nvim_get_current_buf()
local query_lint_on = vim.g.query_lint_on or {}

if not vim.b.disable_query_linter and #query_lint_on > 0 then
  vim.api.nvim_create_autocmd(query_lint_on, {
    group = vim.api.nvim_create_augroup("nvim.querylint", { clear = false }),
    buffer = buf,
    callback = function()
      vim.treesitter.query.lint(buf)
    end,
    desc = "Query linter",
  })
end

vim.cmd([[runtime! ftplugin/lisp.vim]])

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "") .. "\n setl omnifunc< iskeyword<"
vim.b.undo_ftplugin = vim.b.undo_ftplugin .. " | call v:lua.vim.treesitter.stop()"
