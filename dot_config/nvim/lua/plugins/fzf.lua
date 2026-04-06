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
				require("fzf-lua").files({ cwd = project_root() })
			end,
			desc = "Find Files in root",
		},
		{
			"<leader>fF",
			function()
				require("fzf-lua").files()
			end,
			desc = "Find Files in CWD",
		},
		{
			"<leader>fg",
			function()
				require("fzf-lua").live_grep()
			end,
			desc = "Project root with -- *.json glob support",
		},
		{
			"<leader>fs",
			function()
				require("fzf-lua").git_status()
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
				require("fzf-lua").grep_cword()
			end,
			desc = "Grep word",
		},
		{
			"<leader>fW",
			function()
				require("fzf-lua").grep_cWORD()
			end,
			desc = "Grep WORD",
		},
		{
			"<leader>fv",
			function()
				require("fzf-lua").grep_visual()
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
				require("fzf-lua").oldfiles()
			end,
			desc = "Find old file",
		},
	},
	---@diagnostic enable: missing-fields
}
