local function project_root()
	return vim.fs.root(0, { ".git", "package.json", "pyproject.toml", "Cargo.toml" }) or vim.uv.cwd()
end

return {
	"ibhagwan/fzf-lua",
	-- optional for icon support
	-- dependencies = { "nvim-tree/nvim-web-devicons" },
	-- or if using mini.icons/mini.nvim
	-- dependencies = { "nvim-mini/mini.icons" },
	---@module "fzf-lua"
	---@type fzf-lua.Config|{}
	---@diagnostic disable: missing-fields
	opts = {
		ui_select = true,
		git = {
			status = {
				actions = {
					["left"] = false, -- disable stage
					["right"] = false, -- disable unstage
					["ctrl-x"] = false, -- disable reset
				},
			},
		},
	},
	keys = {
		{
			"<leader>ff",
			function()
				require("fzf-lua").files({ cwd = project_root(), path_shorten = 1 })
			end,
			desc = "Find Files in root",
		},
		{
			"<leader>fd",
			function()
				require("fzf-lua").diagnostics_workspace()
			end,
			desc = "Diagnostics workspace",
		},
		{
			"<leader>fD",
			function()
				require("fzf-lua").diagnostics_document()
			end,
			desc = "Diagnostics document",
		},
		{
			"<leader>fF",
			function()
				require("fzf-lua").files({ path_shorten = 1 })
			end,
			desc = "Find Files in CWD",
		},
		{
			"<leader>fg",
			function()
				require("fzf-lua").live_grep({
					cwd = project_root(),
					path_shorten = 1,
					multiline = true,
				})
			end,
			desc = "Project root with -- *.json glob support",
		},
		{
			"<leader>fs",
			function()
				require("fzf-lua").git_status({
					cwd = project_root(),
					path_shorten = 1,
				})
			end,
			desc = "Git Status",
		},
		{
			"<leader>fr",
			function()
				require("fzf-lua").resume()
			end,
			desc = "Resume last fzf",
		},
		{
			"<leader>fw",
			function()
				require("fzf-lua").grep_cword({
					cwd = project_root(),
					path_shorten = 1,
					multiline = true,
				})
			end,
			desc = "Grep word",
		},
		{
			"<leader>fW",
			function()
				require("fzf-lua").grep_cWORD({
					cwd = project_root(),
					path_shorten = 1,
					multiline = true,
				})
			end,
			desc = "Grep WORD",
		},
		{
			"<leader>fv",
			function()
				require("fzf-lua").grep_visual({
					cwd = project_root(),
					path_shorten = 1,
					multiline = true,
				})
			end,
			mode = "x",
			desc = "Grep visual",
		},
		{
			"<leader>/",
			function()
				require("fzf-lua").lgrep_curbuf()
			end,
			desc = "Grep buffer",
		},
		{
			"<leader>fh",
			function()
				require("fzf-lua").helptags()
			end,
			desc = "Find dot file",
		},
		{
			"<leader>fk",
			function()
				require("fzf-lua").keymaps()
			end,
			desc = "Find dot file",
		},
		{
			"<leader>fo",
			function()
				require("fzf-lua").oldfiles({ path_shorten = 1 })
			end,
			desc = "Find old file",
		},
	},
}
