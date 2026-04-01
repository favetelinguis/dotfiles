local root_markers = {
  ".luarc.json",
  ".luarc.jsonc",
  ".stylua.toml",
  "stylua.toml",
  "selene.toml",
  "selene.yml",
  ".git",
}

local function lua_workspace()
  local library = vim.api.nvim_get_runtime_file("", true)
  local config_dir = vim.fn.stdpath("config")

  if not vim.list_contains(library, config_dir) then
    table.insert(library, config_dir)
  end

  local config_lua_dir = vim.fs.joinpath(config_dir, "lua")
  if vim.uv.fs_stat(config_lua_dir) ~= nil and not vim.list_contains(library, config_lua_dir) then
    table.insert(library, config_lua_dir)
  end

  return library
end

---@type vim.lsp.Config
return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = root_markers,
  root_dir = function(bufnr, on_dir)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local config_dir = vim.fn.stdpath("config")

    if bufname ~= "" and vim.startswith(bufname, config_dir) then
      on_dir(config_dir)
      return
    end

    local root = vim.fs.root(bufnr, root_markers)
    if root then
      on_dir(root)
    end
  end,
  settings = {
    Lua = {
      completion = {
        callSnippet = "Replace",
      },
      diagnostics = {
        globals = { "vim" },
      },
      runtime = {
        version = "LuaJIT",
      },
      workspace = {
        checkThirdParty = false,
        library = lua_workspace(),
      },
    },
  },
}
