local M = {}

local group_specs = {
  { "<leader>l", group = "lsp" },
  { "<leader>s", group = "window" },
  { "<leader>p", group = "pack" },
  { "<leader>t", group = "treesitter" },
}

function M.setup()
  local plugins = require("zen_alabaster.plugins")
  if not plugins.load("which-key.nvim") then
    return
  end

  local ok, wk = pcall(require, "which-key")
  if not ok then
    vim.notify("which-key.nvim is installed but unavailable: " .. wk, vim.log.levels.ERROR)
    return
  end

  wk.setup({
    preset = "classic",
    delay = 200,
    icons = {
      mappings = false,
    },
    notify = false,
    plugins = {
      marks = false,
      registers = false,
      spelling = {
        enabled = false,
        suggestions = 20,
      },
      presets = {
        operators = false,
        motions = false,
        text_objects = false,
        windows = false,
        nav = false,
        z = false,
        g = true,
      },
    },
    spec = group_specs,
    triggers = {
      { "<leader>", mode = { "n", "v" } },
      { "g", mode = "n" },
    },
  })
end

return M
