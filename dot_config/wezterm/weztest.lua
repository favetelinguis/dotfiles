local wezterm = require("wezterm")
local weztask = require("weztask")

local module = {}

local function trim(text)
	return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function notify(window, message)
	local text = trim(message)
	if text == "" then
		text = "unknown error"
	end

	if window and window.toast_notification then
		window:toast_notification("WezTest", text, nil, 4000)
	end

	wezterm.log_error(text)
end

local function shorten_command(cmd)
	local normalized = trim((cmd or ""):gsub("%s+", " "))
	if normalized == "" then
		return "test"
	end
	if #normalized > 48 then
		return normalized:sub(1, 45) .. "..."
	end

	return normalized
end

local function parse_payload(value)
	local ok, payload = pcall(wezterm.json_parse, value)
	if not ok then
		return nil, "invalid weztest payload"
	end

	local cmd = trim(payload.cmd)
	local cwd = trim(payload.cwd)
	if cmd == "" then
		return nil, "weztest payload is missing cmd"
	end
	if cwd == "" then
		return nil, "weztest payload is missing cwd"
	end

	return {
		cmd = cmd,
		cwd = cwd,
	}
end

function module.setup()
	wezterm.on("user-var-changed", function(window, pane, name, value)
		if name ~= "weztest" then
			return
		end

		local payload, err = parse_payload(value)
		if not payload then
			notify(window, err)
			return
		end

		local _, spawn_err = weztask.spawn_task_tab(window, pane, {
			name = shorten_command(payload.cmd),
			command = payload.cmd,
			cwd = payload.cwd,
		})
		if spawn_err then
			notify(window, spawn_err)
		end
	end)
end

return module
