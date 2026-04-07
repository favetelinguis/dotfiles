return {
	{
		"folke/lazydev.nvim",
		ft = "lua",
		dependencies = { "DrKJeff16/wezterm-types" },
		opts = {
			library = {
				-- Other library configs...
				{ path = "wezterm-types", mods = { "wezterm" } },
			},
		},
	},
	{
		"mrjones2014/smart-splits.nvim",
		lazy = false,
		opts = {
			multiplexer_integration = "wezterm",
		},
		init = function()
			pcall(vim.keymap.del, "n", "<C-h>")
			pcall(vim.keymap.del, "n", "<C-j>")
			pcall(vim.keymap.del, "n", "<C-k>")
			pcall(vim.keymap.del, "n", "<C-l>")
			pcall(vim.keymap.del, "n", "<C-Up>")
			pcall(vim.keymap.del, "n", "<C-Down>")
			pcall(vim.keymap.del, "n", "<C-Left>")
			pcall(vim.keymap.del, "n", "<C-Right>")
			pcall(vim.keymap.del, "n", "<A-j>")
			pcall(vim.keymap.del, "n", "<A-k>")
			pcall(vim.keymap.del, "v", "<A-j>")
			pcall(vim.keymap.del, "v", "<A-k>")
		end,
		keys = {
			{
				"<A-h>",
				function()
					require("smart-splits").move_cursor_left()
				end,
				desc = "Move to left split or pane",
			},
			{
				"<A-j>",
				function()
					require("smart-splits").move_cursor_down()
				end,
				desc = "Move to lower split or pane",
			},
			{
				"<A-k>",
				function()
					require("smart-splits").move_cursor_up()
				end,
				desc = "Move to upper split or pane",
			},
			{
				"<A-l>",
				function()
					require("smart-splits").move_cursor_right()
				end,
				desc = "Move to right split or pane",
			},
			{
				"<C-h>",
				function()
					require("smart-splits").resize_left()
				end,
				desc = "Resize split left",
			},
			{
				"<C-j>",
				function()
					require("smart-splits").resize_down()
				end,
				desc = "Resize split down",
			},
			{
				"<C-k>",
				function()
					require("smart-splits").resize_up()
				end,
				desc = "Resize split up",
			},
			{
				"<C-l>",
				function()
					require("smart-splits").resize_right()
				end,
				desc = "Resize split right",
			},
		},
	},
}
