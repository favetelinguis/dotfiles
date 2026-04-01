---@type vim.lsp.Config
return {
  cmd = { "ty", "server" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "ty.toml",
    "uv.lock",
    "setup.py",
    "setup.cfg",
    ".git",
  },
  settings = {
    ty = {
      diagnosticMode = "openFilesOnly",
    },
  },
}
