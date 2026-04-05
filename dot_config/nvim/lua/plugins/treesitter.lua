  return {
    {
      "nvim-treesitter/nvim-treesitter",
      branch = "main",
      lazy = false,
      build = ":TSUpdate",
      config = function()
        local ts = require("nvim-treesitter")

        ts.setup({
          install_dir = vim.fn.stdpath("data") .. "/site",
        })

        local parsers = {
          "lua", "java", "json", "yaml", "markdown", "typescript", "helm", "python", "rust", "go", 
          "toml", "javascript", "html", "tsx", "jsx", "xml", "bash", "zsh", "nu", "query", "vim",
          "vimdoc", "markdown_inline", "luadoc"
        }

        ts.install(parsers)

        vim.api.nvim_create_autocmd("FileType", {
          callback = function(args)
            local lang = vim.treesitter.language.get_lang(args.match)
            if not lang then
              return
            end

            pcall(vim.treesitter.start, args.buf, lang)
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            -- vim.wo.foldmethod = "expr"
            -- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          end,
        })
      end,
    },
  }
