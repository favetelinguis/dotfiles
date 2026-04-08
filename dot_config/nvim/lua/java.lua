local java_folding_group = vim.api.nvim_create_augroup("java-folding", { clear = true })

local function close_import_folds(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= "java" then
		return
	end

	for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_call(win, function()
				local view = vim.fn.winsaveview()
				local line_count = vim.api.nvim_buf_line_count(bufnr)
				local lnum = 1

				vim.cmd.normal({ args = { "zx" }, bang = true })

				while lnum <= line_count do
					local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]

					if line and line:match("^import%s") then
						vim.api.nvim_win_set_cursor(0, { lnum, 0 })
						vim.cmd.normal({ args = { "zc" }, bang = true })

						repeat
							lnum = lnum + 1
							line = lnum <= line_count
									and vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
								or nil
						until not line or not line:match("^import%s")
					else
						lnum = lnum + 1
					end
				end

				vim.fn.winrestview(view)
			end)
		end
	end
end

vim.api.nvim_create_autocmd("FileType", {
	group = java_folding_group,
	pattern = "java",
	callback = function(args)
		vim.opt_local.foldmethod = "expr"
		vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.opt_local.foldenable = true

		pcall(vim.treesitter.start, args.buf, "java")

		vim.api.nvim_create_autocmd("BufWinEnter", {
			group = java_folding_group,
			buffer = args.buf,
			once = true,
			callback = function()
				vim.schedule(function()
					close_import_folds(args.buf)
				end)
			end,
		})
	end,
})
