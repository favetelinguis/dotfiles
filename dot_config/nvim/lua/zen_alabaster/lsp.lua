local M = {}

local servers = {
  { name = "lua_ls", executable = "lua-language-server" },
  { name = "ty", executable = "ty" },
  { name = "gopls", executable = "gopls" },
  { name = "rust_analyzer", executable = "rust-analyzer" },
  { name = "jdtls", executable = "jdtls" },
  { name = "ts_ls", executable = "typescript-language-server" },
}

local function map_for_buffer(bufnr, mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer = bufnr,
    silent = true,
    desc = desc,
  })
end

local function toggle_inlay_hints(bufnr)
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
end

function M.setup()
  vim.diagnostic.config({
    severity_sort = true,
    underline = true,
    update_in_insert = false,
    virtual_text = {
      spacing = 2,
      source = "if_many",
    },
    float = {
      border = "rounded",
      source = "if_many",
    },
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("ZenAlabasterLspAttach", { clear = true }),
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      local bufnr = event.buf

      map_for_buffer(bufnr, "n", "gd", vim.lsp.buf.definition, "Goto definition")
      map_for_buffer(bufnr, "n", "gr", vim.lsp.buf.references, "Goto references")
      map_for_buffer(bufnr, "n", "gI", vim.lsp.buf.implementation, "Goto implementation")
      map_for_buffer(bufnr, "n", "gy", vim.lsp.buf.type_definition, "Goto type definition")
      map_for_buffer(bufnr, "n", "K", vim.lsp.buf.hover, "Hover")
      map_for_buffer(bufnr, "n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
      map_for_buffer(bufnr, { "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")

      if client and client:supports_method("textDocument/formatting") then
        map_for_buffer(bufnr, "n", "<leader>lf", function()
          vim.lsp.buf.format({ async = true })
        end, "Format buffer")
      end

      if client and client:supports_method("textDocument/inlayHint") then
        map_for_buffer(bufnr, "n", "<leader>uh", function()
          toggle_inlay_hints(bufnr)
        end, "Toggle inlay hints")
      end
    end,
  })

  for _, server in ipairs(servers) do
    if vim.fn.executable(server.executable) == 1 then
      vim.lsp.enable(server.name)
    else
      vim.schedule(function()
        vim.notify_once(
          string.format("Skipping %s: `%s` is not on PATH", server.name, server.executable),
          vim.log.levels.INFO
        )
      end)
    end
  end
end

return M
