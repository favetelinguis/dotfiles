require("config.options")
require("config.keymaps")

require("flipb").setup({
   mappings = {
     next = "ga",
     prev = nil,
   },
   keys = {
     next = "l",
     prev = "h",
   },
})

require("config.lazy")

-- vim.g.mapleader = " "
-- vim.g.maplocalleader = ","
--
-- local lua_ls_root_markers1 = {
--   ".emmyrc.json",
--   ".luarc.json",
--   ".luarc.jsonc",
-- }
-- local lua_ls_root_markers2 = {
--   ".luacheckrc",
--   ".stylua.toml",
--   "stylua.toml",
--   "selene.toml",
--   "selene.yml",
-- }
--
-- vim.pack.add({
--   { src = "https://github.com/neovim/nvim-lspconfig" },
--   { src = "https://github.com/folke/lazydev.nvim" },
--   { src = "https://github.com/DrKJeff16/wezterm-types" },
-- }, {
--   confirm = false,
-- })
--
-- require("lazydev").setup({
--   library = {
--     { path = "${3rd}/luv/library", words = { "vim%.uv" } },
--     { path = "wezterm-types", mods = { "wezterm" } },
--   },
-- })
--
-- vim.lsp.config("lua_ls", {
--   on_init = function(client)
--     if client.workspace_folders then
--       local path = client.workspace_folders[1].name
--       if
--         path ~= vim.fn.stdpath("config")
--         and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
--       then
--         return
--       end
--     end
--
--     client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
--       runtime = {
--         version = "LuaJIT",
--         path = {
--           "lua/?.lua",
--           "lua/?/init.lua",
--         },
--       },
--       workspace = {
--         checkThirdParty = false,
--         library = {
--           vim.env.VIMRUNTIME,
--         },
--       },
--     })
--   end,
--   root_markers = vim.fn.has("nvim-0.11.3") == 1
--       and { lua_ls_root_markers1, lua_ls_root_markers2, { ".git" } }
--     or vim.list_extend(vim.list_extend(lua_ls_root_markers1, lua_ls_root_markers2), { ".git" }),
--   settings = {
--     Lua = {},
--   },
-- })
--
-- vim.lsp.enable("lua_ls")
