local M = {}

function M.setup()
	vim.keymap.set("x", "<leader>ra", function()
		local other = require("other")
		local selection = other.visual_selection()
		if not selection then
			return
		end

		other.send_request({
			mode = "select",
			kind = "ai",
			paste = true,
			cmd = other.file_location_text(selection.text, selection.start_line),
		})
	end, { desc = "Send selection to AI" })
end

return M
