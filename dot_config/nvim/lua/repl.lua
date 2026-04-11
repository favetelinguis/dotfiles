local M = {}

function M.setup()
	vim.keymap.set("x", "<leader>rr", function()
		local other = require("other")
		local selection = other.visual_selection()
		if not selection then
			return
		end

		other.send_request({
			mode = "select",
			kind = "repl",
			cmd = selection.text,
		})
	end, { desc = "Send selection to REPL" })
end

return M
