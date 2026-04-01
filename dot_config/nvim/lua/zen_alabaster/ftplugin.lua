local M = {}

function M.safe_treesitter_start(lang)
  return pcall(vim.treesitter.start, 0, lang)
end

function M.set_heading_maps()
  vim.keymap.set("n", "gO", function()
    require("vim.treesitter._headings").show_toc()
  end, { buffer = 0, silent = true, desc = "Show an Outline of the current buffer" })

  vim.keymap.set("n", "]]", function()
    require("vim.treesitter._headings").jump({ count = 1 })
  end, { buffer = 0, silent = false, desc = "Jump to next section" })

  vim.keymap.set("n", "[[", function()
    require("vim.treesitter._headings").jump({ count = -1 })
  end, { buffer = 0, silent = false, desc = "Jump to previous section" })
end

return M
