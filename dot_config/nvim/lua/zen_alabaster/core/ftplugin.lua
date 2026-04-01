vim.g.did_load_ftplugin = 1

local M = {}

local runtime_ftplugin_dir = vim.fs.joinpath(vim.env.VIMRUNTIME or "", "ftplugin")
local skipped_runtime_ftplugins = {
  help = true,
  lua = true,
  markdown = true,
  query = true,
}

local function should_skip(path)
  return vim.startswith(path, runtime_ftplugin_dir) and skipped_runtime_ftplugins[vim.fs.basename(path):gsub("%.lua$", "")]
end

local function source_matches(pattern)
  for _, path in ipairs(vim.api.nvim_get_runtime_file(pattern, true)) do
    if not should_skip(path) then
      vim.cmd.source(vim.fn.fnameescape(path))
    end
  end
end

local function load_ftplugins(ev)
  if vim.b.undo_ftplugin then
    vim.cmd(vim.b.undo_ftplugin)
    vim.b.undo_ftplugin = nil
    vim.b.did_ftplugin = nil
  end

  if ev.match == "" then
    return
  end

  for _, name in ipairs(vim.split(ev.match, ".", { plain = true })) do
    source_matches("ftplugin/" .. name .. ".vim")
    source_matches("ftplugin/" .. name .. ".lua")
    source_matches("ftplugin/" .. name .. "_*.vim")
    source_matches("ftplugin/" .. name .. "_*.lua")
    source_matches("ftplugin/" .. name .. "/*.vim")
    source_matches("ftplugin/" .. name .. "/*.lua")
  end
end

function M.setup()
  vim.api.nvim_create_augroup("filetypeplugin", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = "filetypeplugin",
    callback = function(ev)
      vim._with({ buf = ev.buf }, function()
        load_ftplugins(ev)
      end)
    end,
  })
end

return M
