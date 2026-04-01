local M = {}

local specs = {
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
}

local function plugin_dir(name)
  return vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt", name)
end

local function installed(name)
  return vim.uv.fs_stat(plugin_dir(name)) ~= nil
end

local function configure_treesitter()
  local ok, configs = pcall(require, "nvim-treesitter.configs")
  if not ok then
    return
  end

  configs.setup({
    auto_install = false,
    sync_install = false,
    ensure_installed = {},
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = false,
    },
  })
end

function M.setup()
  if installed("nvim-treesitter") then
    vim.cmd.packadd("nvim-treesitter")
    configure_treesitter()
  end

  vim.api.nvim_create_user_command("PackSync", function()
    vim.pack.add(specs, { confirm = true })
    configure_treesitter()
  end, { desc = "Install configured plugins with vim.pack" })

  vim.api.nvim_create_user_command("PackUpdate", function()
    vim.pack.update()
  end, { desc = "Update vim.pack plugins" })
end

return M
