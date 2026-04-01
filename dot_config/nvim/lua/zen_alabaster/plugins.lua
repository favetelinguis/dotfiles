local M = {}

local specs = {
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  { src = "https://github.com/folke/which-key.nvim" },
}

local managed_parsers = {
  "lua",
  "vim",
  "vimdoc",
  "query",
  "markdown",
  "markdown_inline",
  "java",
  "javascript",
  "typescript",
  "tsx",
  "python",
  "go",
  "rust",
}

local function plugin_dir(name)
  return vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt", name)
end

function M.installed(name)
  return vim.uv.fs_stat(plugin_dir(name)) ~= nil
end

function M.load(name)
  if not M.installed(name) then
    return false
  end

  local ok, err = pcall(vim.cmd.packadd, name)
  if not ok then
    vim.notify("Unable to load " .. name .. ": " .. err, vim.log.levels.ERROR)
    return false
  end

  return true
end

local function load_treesitter_commands()
  if not M.installed("nvim-treesitter") then
    vim.notify("nvim-treesitter is not installed. Run :PackSync first.", vim.log.levels.WARN)
    return false
  end

  if not M.load("nvim-treesitter") then
    return false
  end

  return true
end

local function run_treesitter_command(command)
  if not load_treesitter_commands() then
    return
  end

  vim.cmd({ cmd = command, args = managed_parsers })
end

function M.setup()
  vim.pack.add(specs, { confirm = true })

  vim.api.nvim_create_user_command("PackSync", function()
    vim.pack.add(specs, { confirm = true })
  end, { desc = "Install configured plugins with vim.pack" })

  vim.api.nvim_create_user_command("PackUpdate", function()
    vim.pack.update()
  end, { desc = "Update vim.pack plugins" })

  vim.api.nvim_create_user_command("TSInstallManaged", function()
    run_treesitter_command("TSInstall")
  end, { desc = "Install the managed Tree-sitter parser set" })

  vim.api.nvim_create_user_command("TSUpdateManaged", function()
    run_treesitter_command("TSUpdate")
  end, { desc = "Update the managed Tree-sitter parser set" })
end

return M
