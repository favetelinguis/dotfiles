local ftplugin = require("zen_alabaster.ftplugin")

ftplugin.safe_treesitter_start()

local function colorize_hl_groups(patterns)
  local ns = vim.api.nvim_create_namespace("nvim.vimhelp")
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

  local save_cursor = vim.fn.getcurpos()

  for _, pat in pairs(patterns) do
    local start_lnum = vim.fn.search(pat.start, "c")
    local end_lnum = vim.fn.search(pat.stop)
    if start_lnum == 0 or end_lnum == 0 then
      break
    end

    for lnum = start_lnum, end_lnum do
      local word = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]:match(pat.match)
      if vim.fn.hlexists(word) ~= 0 then
        vim.api.nvim_buf_set_extmark(0, ns, lnum - 1, 0, { end_col = #word, hl_group = word })
      end
    end
  end

  vim.fn.setpos(".", save_cursor)
end

local bufname = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
if vim.endswith(bufname, "/doc/syntax.txt") then
  colorize_hl_groups({
    { start = [[\*group-name\*]], stop = "^======", match = "^(%w+)\t" },
    { start = [[\*highlight-groups\*]], stop = "^======", match = "^(%w+)\t" },
  })
elseif vim.endswith(bufname, "/doc/treesitter.txt") then
  colorize_hl_groups({
    {
      start = [[\*treesitter-highlight-groups\*]],
      stop = [[\*treesitter-highlight-spell\*]],
      match = "^@[%w%p]+",
    },
  })
elseif vim.endswith(bufname, "/doc/diagnostic.txt") then
  colorize_hl_groups({
    { start = [[\*diagnostic-highlights\*]], stop = "^======", match = "^(%w+)" },
  })
elseif vim.endswith(bufname, "/doc/lsp.txt") then
  colorize_hl_groups({
    { start = [[\*lsp-highlight\*]], stop = "^------", match = "^(%w+)" },
    { start = [[\*lsp-semantic-highlight\*]], stop = "^======", match = "^@[%w%p]+" },
  })
end

ftplugin.set_heading_maps()

local ok_parser, parser = pcall(vim.treesitter.get_parser, 0, "vimdoc")
if ok_parser then
  local function runnables()
    local code_blocks = {}
    local ok_query, query = pcall(vim.treesitter.query.parse, "vimdoc", [[
      (codeblock
        (language) @_lang
        .
        (code) @code
        (#any-of? @_lang "lua" "vim")
        (#set! @code lang @_lang))
    ]])
    if not ok_query then
      return
    end

    local root = parser:parse()[1]:root()
    for _, match, metadata in query:iter_matches(root, 0, 0, -1) do
      for id, nodes in pairs(match) do
        local name = query.captures[id]
        local node = nodes[1]
        local start, _, end_ = node:parent():range()

        if name == "code" then
          local code = vim.treesitter.get_node_text(node, 0)
          local lang_node = match[metadata[id].lang][1]
          local lang = vim.treesitter.get_node_text(lang_node, 0)
          for i = start + 1, end_ do
            code_blocks[i] = { lang = lang, code = code }
          end
        end
      end
    end

    vim.keymap.set("n", "g==", function()
      local pos = vim.api.nvim_win_get_cursor(0)[1]
      local code_block = code_blocks[pos]
      if not code_block then
        vim.print("No code block found")
      elseif code_block.lang == "lua" then
        vim.cmd.lua(code_block.code)
      elseif code_block.lang == "vim" then
        vim.cmd(code_block.code)
      end
    end, { buffer = 0 })
  end

  pcall(runnables)
end
