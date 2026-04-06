return {
	"xvzc/chezmoi.nvim",
	dependencies = {
		"ibhagwan/fzf-lua",
		"nvim-lua/plenary.nvim",
	},
	cmd = { "ChezmoiEdit", "ChezmoiList" },
	keys = {
		{
			"<leader>f.",
			function()
				require("chezmoi.pick").fzf()
			end,
			desc = "Chezmoi files",
		},
	},
	init = function()
		local source_root = vim.fs.normalize(vim.fn.expand("~/.local/share/chezmoi"))
		local group = vim.api.nvim_create_augroup("chezmoi-auto-watch", { clear = true })

		vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
			group = group,
			pattern = { source_root .. "/*" },
			callback = function(ev)
				vim.schedule(function()
					require("chezmoi.commands.__edit").watch(ev.buf)
				end)
			end,
		})
	end,
	opts = {
		edit = {
			watch = false,
			force = false,
		},
		events = {
			on_open = {
				notification = {
					enable = true,
				},
			},
			on_watch = {
				notification = {
					enable = false,
				},
			},
			on_apply = {
				notification = {
					enable = true,
				},
			},
		},
	},
}
