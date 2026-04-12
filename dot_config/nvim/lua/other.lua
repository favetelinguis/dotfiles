local M = {}

local state = {
	is_setup = false,
}

local user_var_name = "other"

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "other" })
end

local function current_file_path()
	local path = vim.fn.expand("%:.")
	if path == "" then
		path = vim.api.nvim_buf_get_name(0)
	end
	if path == "" then
		return nil
	end

	return path
end

local function get_visual_text()
	local mode = vim.fn.mode()
	if not mode:match("[vV\22]") then
		mode = vim.fn.visualmode()
	end

	if not mode:match("[vV\22]") then
		return nil, nil
	end

	local start_pos = vim.fn.getpos("v")
	local end_pos = vim.fn.getcurpos()
	local start_line = math.min(start_pos[2], end_pos[2])
	local lines = vim.fn.getregion(start_pos, end_pos, {
		type = mode,
		exclusive = vim.o.selection == "exclusive",
	})

	local text = table.concat(lines, "\n")
	if mode == "V" then
		text = text .. "\n"
	end

	return text, start_line
end

local function with_file_location(text, start_line)
	local path = current_file_path()
	if not path then
		return text
	end

	return string.format("%s:%d\n%s", path, start_line, text)
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
	payload.paste = payload.paste == true

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

	if payload.mode == "remove" and payload.kind == "" then
		notify("remove requests require a kind", vim.log.levels.ERROR)
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

function M.visual_selection()
	local text, start_line = get_visual_text()
	if not text or text == "" then
		notify("visual selection required", vim.log.levels.ERROR)
		return nil
	end

	return {
		text = text,
		start_line = start_line,
	}
end

function M.file_location_text(text, start_line)
	return with_file_location(text, start_line)
end

function M.remove(kind)
	local normalized_kind = vim.trim(kind or "")
	if normalized_kind == "" then
		notify("remove requires a kind", vim.log.levels.ERROR)
		return false
	end

	return M.send_request({
		mode = "remove",
		kind = normalized_kind,
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

	vim.keymap.set("n", "<leader>rA", function()
		M.remove("ai")
	end, { desc = "Clear AI pane association" })

	vim.keymap.set("n", "<leader>rR", function()
		M.remove("repl")
	end, { desc = "Clear REPL pane association" })

	vim.keymap.set("n", "<leader>rT", function()
		M.remove("test")
	end, { desc = "Clear test pane association" })
end

return M
