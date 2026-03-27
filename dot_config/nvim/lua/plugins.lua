vim.pack.add({
    { src = "https://github.com/lewis6991/gitsigns.nvim" },
    { src = "https://github.com/phha/zenburn.nvim" },
    { src = "https://github.com/tpope/vim-fugitive" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
    { src = "https://github.com/pwntester/octo.nvim" },
})

local ok_gitsigns, gitsigns = pcall(require, "gitsigns")
if ok_gitsigns then
    gitsigns.setup({ signcolumn = false })
end

local ok_zenburn, zenburn = pcall(require, "zenburn")
if ok_zenburn then
    zenburn.setup({})
    vim.cmd.colorscheme("zenburn")
end

local ok_octo, octo = pcall(require, "octo")
if ok_octo then
    octo.setup({
        enable_builtin = true,
        picker = "default",
        use_local_fs = true,
        default_remote = { "upstream", "origin" },
        picker_config = {
            search_static = true,
        },
        suppress_missing_scope = {
            projects_v2 = true,
        },
    })

    pcall(vim.treesitter.language.register, "markdown", "octo")
end
