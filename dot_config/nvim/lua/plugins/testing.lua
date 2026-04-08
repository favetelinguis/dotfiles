return {
	"vim-test/vim-test",
	cmd = {
		"TestNearest",
		"TestFile",
		"TestSuite",
		"TestLast",
		"TestVisit",
		"TestClass",
	},
	keys = {
		{ "<leader>r", desc = "Run tests" },
		{ "<leader>rn", "<cmd>TestNearest<CR>", desc = "Run nearest test" },
		{ "<leader>rf", "<cmd>TestFile<CR>", desc = "Run test file" },
		{ "<leader>rs", "<cmd>TestSuite<CR>", desc = "Run test suite" },
		{ "<leader>rl", "<cmd>TestLast<CR>", desc = "Run last test" },
		{ "<leader>rv", "<cmd>TestVisit<CR>", desc = "Visit last test file" },
		{ "<leader>rc", "<cmd>TestClass<CR>", desc = "Run test class" },
	},
	init = function()
		vim.g["test#strategy"] = "wezterm"
	end,
}
