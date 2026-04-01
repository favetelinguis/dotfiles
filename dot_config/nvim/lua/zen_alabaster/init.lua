local M = {}

function M.setup()
  require("zen_alabaster.core.options")
  require("zen_alabaster.core.ftplugin").setup()
  require("zen_alabaster.core.autocmds")
  require("zen_alabaster.core.commands")
  require("zen_alabaster.core.keymaps")
  require("zen_alabaster.plugins").setup()
  require("zen_alabaster.theme").setup()
  require("zen_alabaster.lsp").setup()
end

return M
