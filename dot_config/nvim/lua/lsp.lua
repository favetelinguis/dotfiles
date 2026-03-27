vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  virtual_text = {
    spacing = 2,
    source = "if_many",
  },
  float = {
    border = "rounded",
  },
})

vim.lsp.enable({
  "lua_ls",
  "rust-analyzer",
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(event)
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, {
        buffer = event.buf,
        silent = true,
        desc = desc,
      })
    end

    map("n", "gd", vim.lsp.buf.definition, "Goto definition")
    map("n", "gr", vim.lsp.buf.references, "Goto references")
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>lf", function()
      vim.lsp.buf.format({ async = true })
    end, "Format buffer")
    map("n", "[d", function()
      vim.diagnostic.jump({ count = -1, float = true })
    end, "Previous diagnostic")
    map("n", "]d", function()
      vim.diagnostic.jump({ count = 1, float = true })
    end, "Next diagnostic")
  end,
})
