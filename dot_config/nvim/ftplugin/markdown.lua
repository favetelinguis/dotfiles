local ftplugin = require("zen_alabaster.ftplugin")

ftplugin.safe_treesitter_start()
ftplugin.set_heading_maps()

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "")
  .. "\n call v:lua.vim.treesitter.stop()"
  .. "\n sil! exe \"nunmap <buffer> gO\""
  .. "\n sil! exe \"nunmap <buffer> ]]\" | sil! exe \"nunmap <buffer> [[\""
