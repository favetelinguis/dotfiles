local function send(text)
	vim.fn["slime#send"](text .. "\r")
end

local function resolve_pane_id()
	local result = vim.system({ "wezterm", "cli", "get-pane-direction", "right" }, { text = true }):wait()
	if result.code ~= 0 then
		local message = vim.trim(result.stderr or result.stdout or "failed to resolve WezTerm pane")
		vim.notify("vim-slime: " .. message, vim.log.levels.ERROR)
		return nil
	end

	local pane_id = vim.trim(result.stdout or "")
	if pane_id == "" then
		vim.notify("vim-slime: no WezTerm pane found to the right", vim.log.levels.ERROR)
		return nil
	end

	return pane_id
end

local function ensure_slime_config()
	local config = vim.b.slime_config
	if type(config) == "table" and config.pane_id and config.pane_id ~= "" then
		return true
	end

	local pane_id = resolve_pane_id()
	if not pane_id then
		return false
	end

	vim.b.slime_config = { pane_id = pane_id }
	return true
end

local function current_file()
	local path = vim.fn.expand("%:.")
	if path == "" then
		path = vim.api.nvim_buf_get_name(0)
	end
	if path == "" then
		path = "[No Name]"
	end
	return path
end

local function make_header(line)
	return string.format("%s:%d", current_file(), line)
end

local function get_visual_text()
	local mode = vim.fn.mode()
	if not mode:match("[vV\22]") then
		mode = vim.fn.visualmode()
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

local function capture_paragraph()
	local view = vim.fn.winsaveview()
	local register = vim.fn.getreg('"')
	local register_type = vim.fn.getregtype('"')
	local selection = vim.o.selection

	vim.o.selection = "inclusive"
	vim.cmd.normal({ args = { "vipy" }, bang = true })

	local text = vim.fn.getreg('"')
	local start_line = vim.fn.getpos("'<")[2]

	vim.fn.setreg('"', register, register_type)
	vim.o.selection = selection
	vim.fn.winrestview(view)

	return text, start_line
end

local function send_with_header_paragraph()
	if not ensure_slime_config() then
		return
	end

	local text, start_line = capture_paragraph()
	send(make_header(start_line) .. "\n" .. text)
end

local function send_with_header_visual()
	if not ensure_slime_config() then
		return
	end

	local text, start_line = get_visual_text()
	send(make_header(start_line) .. "\n" .. text)
end

local function send_paragraph()
	if not ensure_slime_config() then
		return
	end

	local text = capture_paragraph()
	send(text)
end

local function send_visual()
	if not ensure_slime_config() then
		return
	end

	local text = get_visual_text()
	send(text)
end

return {
	"jpalardy/vim-slime",
	cmd = {
		"SlimeConfig",
		"SlimeSend",
		"SlimeSend0",
		"SlimeSend1",
		"SlimeSendCurrentLine",
	},
	keys = {
		{
			"<leader>rr",
			function()
				send_paragraph()
			end,
			mode = "n",
			desc = "Send paragraph to REPL",
		},
		{
			"<leader>rr",
			function()
				send_visual()
			end,
			mode = "x",
			desc = "Send selection to REPL",
		},
		{
			"<leader>rR",
			function()
				send_with_header_paragraph()
			end,
			mode = "n",
			desc = "Send paragraph with location",
		},
		{
			"<leader>rR",
			function()
				send_with_header_visual()
			end,
			mode = "x",
			desc = "Send selection with location",
		},
	},
	init = function()
		vim.g.slime_target = "wezterm"
		vim.g.slime_no_mappings = 1
		_G.slime_wezterm_override_config = function()
			local pane_id = resolve_pane_id()
			if pane_id then
				vim.b.slime_config = { pane_id = pane_id }
			end
		end
		vim.cmd([[
			function! SlimeOverrideConfig() abort
				call v:lua.slime_wezterm_override_config()
			endfunction
		]])
	end,
}
