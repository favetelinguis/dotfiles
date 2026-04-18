---@module 'lazy'
---@type LazySpec
return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	keys = {
		{
			"<leader>cc",
			function()
				local lint = require("lint")
				local bufnr = vim.api.nvim_get_current_buf()
				local filetype = vim.bo[bufnr].filetype

				if filetype == "rust" then
					local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "rust_analyzer" })
					local root = clients[#clients] and clients[#clients].config.root_dir
					root = root or vim.fs.root(vim.api.nvim_buf_get_name(bufnr), { "Cargo.toml", "rust-project.json", ".git" })
					lint.try_lint("clippy", { cwd = root or vim.fn.getcwd() })
					return
				end

				lint.try_lint()
			end,
			desc = "[C]ode [C]heck",
		},
	},
	config = function()
		local lint = require("lint")

		local function rust_lint_cwd(bufnr)
			local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "rust_analyzer" })
			local root = clients[#clients] and clients[#clients].config.root_dir
			return root or vim.fs.root(vim.api.nvim_buf_get_name(bufnr), { "Cargo.toml", "rust-project.json", ".git" })
		end

		local function lint_buffer(bufnr, names)
			if vim.bo[bufnr].filetype == "rust" then
				lint.try_lint(names or "clippy", { cwd = rust_lint_cwd(bufnr) or vim.fn.getcwd() })
				return
			end

			lint.try_lint(names)
		end

		lint.linters_by_ft = {
			rust = { "clippy" },
			-- markdown = { "markdownlint" }, -- Make sure to install `markdownlint` via mason / npm
		}

		-- To allow other plugins to add linters to require('lint').linters_by_ft,
		-- instead set linters_by_ft like this:
		-- lint.linters_by_ft = lint.linters_by_ft or {}
		-- lint.linters_by_ft['markdown'] = { 'markdownlint' }
		--
		-- However, note that this will enable a set of default linters,
		-- which will cause errors unless these tools are available:
		-- {
		--   clojure = { "clj-kondo" },
		--   dockerfile = { "hadolint" },
		--   inko = { "inko" },
		--   janet = { "janet" },
		--   json = { "jsonlint" },
		--   markdown = { "vale" },
		--   rst = { "vale" },
		--   ruby = { "ruby" },
		--   terraform = { "tflint" },
		--   text = { "vale" }
		-- }
		--
		-- You can disable the default linters by setting their filetypes to nil:
		-- lint.linters_by_ft['clojure'] = nil
		-- lint.linters_by_ft['dockerfile'] = nil
		-- lint.linters_by_ft['inko'] = nil
		-- lint.linters_by_ft['janet'] = nil
		-- lint.linters_by_ft['json'] = nil
		-- lint.linters_by_ft['markdown'] = nil
		-- lint.linters_by_ft['rst'] = nil
		-- lint.linters_by_ft['ruby'] = nil
		-- lint.linters_by_ft['terraform'] = nil
		-- lint.linters_by_ft['text'] = nil

		-- Create autocommand which carries out the actual linting
		-- on the specified events.
		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				if vim.bo.filetype == "rust" then
					return
				end

				-- Only run the linter in buffers that you can modify in order to
				-- avoid superfluous noise, notably within the handy LSP pop-ups that
				-- describe the hovered symbol using Markdown.
				if vim.bo.modifiable then
					lint_buffer(vim.api.nvim_get_current_buf())
				end
			end,
		})

		vim.api.nvim_create_autocmd("FileType", {
			group = lint_augroup,
			pattern = "rust",
			callback = function(args)
				vim.api.nvim_buf_create_user_command(args.buf, "RustClippy", function()
					lint_buffer(args.buf, "clippy")
				end, { desc = "Run cargo clippy for the current Rust buffer" })
			end,
		})
	end,
}
