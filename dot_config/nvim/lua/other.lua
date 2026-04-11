local M = {}

local state = {
	is_setup = false,
}

local user_var_name = "other"

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "other" })
end

local function get_visual_text()
	local mode = vim.fn.mode()
	if not mode:match("[vV\22]") then
		mode = vim.fn.visualmode()
	end

	if not mode:match("[vV\22]") then
		return nil
	end

	local start_pos = vim.fn.getpos("v")
	local end_pos = vim.fn.getcurpos()
	local lines = vim.fn.getregion(start_pos, end_pos, {
		type = mode,
		exclusive = vim.o.selection == "exclusive",
	})

	local text = table.concat(lines, "\n")
	if mode == "V" then
		text = text .. "\n"
	end

	return text
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

local function normalize_request(request)
	local payload = vim.deepcopy(request or {})
	payload.mode = vim.trim(payload.mode or "")
	payload.kind = vim.trim(payload.kind or "")

	if payload.mode == "selector" then
		payload.mode = "select"
		if payload.kind == "" then
			payload.kind = "selection"
		end
	end

	if payload.mode == "select" and payload.kind == "" then
		notify("select requests require a kind", vim.log.levels.ERROR)
		return nil
	end

	return payload
end

function M.send_request(request)
	local normalized = normalize_request(request)
	if not normalized then
		return false
	end

	local payload = vim.tbl_extend("keep", normalized, {
		cwd = vim.fn.getcwd(),
	})

	return send_user_var(user_var_name, vim.json.encode(payload))
end

function M.send_visual_selection()
	local text = get_visual_text()
	if not text or text == "" then
		notify("visual selection required", vim.log.levels.ERROR)
		return
	end

	M.send_request({
		mode = "select",
		kind = "selection",
		cmd = text,
	})
end

function M.setup()
	if state.is_setup then
		return
	end

	state.is_setup = true

	vim.keymap.set("x", "<leader>z", function()
		M.send_visual_selection()
	end, { desc = "Send selection to WezTerm" })
end

return M
