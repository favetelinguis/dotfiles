local function shorten_command(cmd)
	local normalized = (cmd or ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if normalized == "" then
		return "test"
	end
	if #normalized > 48 then
		return normalized:sub(1, 45) .. "..."
	end

	return normalized
end

local function dispatch_test_command(cmd)
	require("other").send_request({
		mode = "select",
		kind = "test",
		cmd = "clear\n" .. cmd,
		cwd = vim.fn.getcwd(),
		title = shorten_command(cmd),
	})
end

local function register_strategy()
	if vim.g.weztest_strategy_registered == 1 then
		return
	end

	_G.__weztest_vim_test_strategy = dispatch_test_command
	vim.cmd([[
		function! WeztestVimTestStrategy(cmd) abort
			call v:lua.__weztest_vim_test_strategy(a:cmd)
		endfunction

		let g:test#custom_strategies = get(g:, 'test#custom_strategies', {})
		let g:test#custom_strategies.weztest = function('WeztestVimTestStrategy')
	]])
	vim.g.weztest_strategy_registered = 1
end

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
		register_strategy()
		vim.g["test#strategy"] = "weztest"
	end,
}
