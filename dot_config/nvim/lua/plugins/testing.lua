local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "weztest" })
end

local function send_user_var(name, value)
	if not vim.api.nvim_ui_send then
		notify("nvim_ui_send() is unavailable in this Neovim build", vim.log.levels.ERROR)
		return false
	end

	local encoded = vim.base64.encode(value)
	local osc = string.format("\027]1337;SetUserVar=%s=%s\007", name, encoded)

	vim.api.nvim_ui_send(osc)
	return true
end

local function dispatch_test_command(cmd)
	local payload = vim.json.encode({
		cmd = cmd,
		cwd = vim.fn.getcwd(),
	})

	send_user_var("weztest", payload)
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
