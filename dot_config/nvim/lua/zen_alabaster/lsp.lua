local M = {}
local lsp_util = vim.lsp.util

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

local function has_markdown_parser()
  return not vim.tbl_isempty(vim.api.nvim_get_runtime_file("parser/markdown.*", true))
end

local function hover_with_fallback()
  if has_markdown_parser() or vim.g.syntax_on == nil then
    vim.lsp.buf.hover()
    return
  end

  local win = vim.api.nvim_get_current_win()

  vim.lsp.buf_request_all(0, "textDocument/hover", function(client)
    return lsp_util.make_position_params(win, client.offset_encoding)
  end, function(results, ctx)
    local bufnr = assert(ctx.bufnr)
    if vim.api.nvim_get_current_buf() ~= bufnr then
      return
    end

    local hover_results = {}
    local empty_response = false

    for client_id, resp in pairs(results) do
      local err, result = resp.err, resp.result
      if err then
        vim.lsp.log.error(err.code, err.message)
      elseif result and result.contents then
        local text = type(result.contents) == "table"
            and (vim.tbl_get(result.contents, "value")
              or vim.tbl_get(result.contents, 1, "value")
              or result.contents[1]
              or "")
          or result.contents

        if type(text) == "string" and #text > 0 then
          hover_results[client_id] = result
        else
          empty_response = true
        end
      end
    end

    if vim.tbl_isempty(hover_results) then
      if empty_response then
        vim.notify("Empty hover response", vim.log.levels.INFO)
      else
        vim.notify("No information available", vim.log.levels.INFO)
      end
      return
    end

    local contents = {}
    local multiple_clients = vim.tbl_count(hover_results) > 1

    for client_id, result in pairs(hover_results) do
      local client = assert(vim.lsp.get_client_by_id(client_id))

      if multiple_clients then
        contents[#contents + 1] = string.format("[%s]", client.name)
      end

      if type(result.contents) == "table" and result.contents.kind == "plaintext" then
        vim.list_extend(contents, vim.split(result.contents.value or "", "\n", { trimempty = true }))
      else
        vim.list_extend(contents, lsp_util.convert_input_to_markdown_lines(result.contents))
      end

      if multiple_clients then
        contents[#contents + 1] = string.rep("-", 48)
      end
    end

    if multiple_clients then
      contents[#contents] = nil
    end

    lsp_util.open_floating_preview(contents, "plaintext", {
      border = "rounded",
      focus_id = "textDocument/hover",
    })
  end)
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
      map_for_buffer(bufnr, "n", "K", hover_with_fallback, "Hover")
      map_for_buffer(bufnr, "n", "<leader>lr", vim.lsp.buf.rename, "Rename symbol")
      map_for_buffer(bufnr, { "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "Code action")
      map_for_buffer(bufnr, "n", "<leader>ls", vim.lsp.buf.document_symbol, "Document symbols")

      if client and client:supports_method("textDocument/formatting") then
        map_for_buffer(bufnr, "n", "<leader>lf", function()
          vim.lsp.buf.format({ async = true })
        end, "Format buffer")
      end

      if client and client:supports_method("textDocument/inlayHint") then
        map_for_buffer(bufnr, "n", "<leader>lh", function()
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
