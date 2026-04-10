local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

local state = {
	is_setup = false,
}

local user_var_name = "other"
local task_title_prefix = "weztask:"
local task_banner = "WezTask"
local shell = "/bin/zsh"
local task_colors = {
	running = "#e0af68",
	failure = "#f7768e",
	success = "#9ece6a",
	text = "#15161e",
}
local valid_modes = {
	tab = true,
	selector = true,
}

local function trim(text)
	return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function basename(path)
	return string.gsub(path or "", "(.*[/\\])(.*)", "%2")
end

local function shell_quote(value)
	return "'" .. tostring(value):gsub("'", [["'"']]) .. "'"
end

local function title_escape(title)
	return string.format("\\033]2;%s\\007", title)
end

local function make_state_title(task_state)
	return string.format("%s%s", task_title_prefix, task_state)
end

local function parse_task_state(title)
	if type(title) ~= "string" then
		return nil
	end

	local task_state = title:match("^" .. task_title_prefix .. "([^:]+)$")
	if not task_state or not task_colors[task_state] then
		return nil
	end

	return task_state
end

local function current_cwd(pane)
	local cwd_url = pane and pane:get_current_working_dir() or nil
	return cwd_url and cwd_url.file_path or nil
end

local function default_title(tab)
	if tab.tab_title and #tab.tab_title > 0 then
		return tab.tab_title
	end

	return tab.active_pane and tab.active_pane.title or nil
end

local function zoom_prefix(tab)
	return tab.active_pane.is_zoomed and "[Z] " or ""
end

local function format_default_tab_title(tab)
	return string.format(" %d: %s%s ", tab.tab_index + 1, zoom_prefix(tab), default_title(tab))
end

local function format_task_tab_title(tab, task_state, name)
	return {
		{ Background = { Color = task_colors[task_state] } },
		{ Foreground = { Color = task_colors.text } },
		{ Text = string.format(" %d: %s%s ", tab.tab_index + 1, zoom_prefix(tab), name) },
	}
end

local function shorten_command(cmd)
	local normalized = trim((cmd or ""):gsub("%s+", " "))
	if normalized == "" then
		return "task"
	end
	if #normalized > 48 then
		return normalized:sub(1, 45) .. "..."
	end

	return normalized
end

local function task_script(name, command)
	local running_title = make_state_title("running")
	local success_title = make_state_title("success")
	local failure_title = make_state_title("failure")
	local success_message = string.format("\nTask succeeded: %s\n", name)
	local failure_format = string.format("\nTask failed (%s), exit %%s\n", name)

	return table.concat({
		"printf " .. shell_quote(title_escape(running_title)),
		"set +e",
		command,
		"task_status=$?",
		"if [ \"$task_status\" -eq 0 ]; then",
		"  printf " .. shell_quote(title_escape(success_title)),
		"  printf " .. shell_quote(success_message),
		"else",
		"  printf " .. shell_quote(title_escape(failure_title)),
		"  printf " .. shell_quote(failure_format) .. " \"$task_status\"",
		"fi",
		"printf 'This task tab will stay open until you close it manually.\\n'",
		"exec tail -f /dev/null",
	}, "\n")
end

local function parse_request(value)
	local ok, request = pcall(wezterm.json_parse, value)
	if not ok or type(request) ~= "table" then
		return nil, "invalid other payload"
	end

	return request
end

local function normalize_request(pane, request)
	local mode = trim(request.mode)
	local cmd = trim(request.cmd)
	local cwd = trim(request.cwd)
	local title = trim(request.title)

	if not valid_modes[mode] then
		return nil, "other payload is missing a valid mode"
	end
	if cmd == "" then
		return nil, "other payload is missing cmd"
	end

	if mode == "tab" then
		if cwd == "" then
			cwd = trim(current_cwd(pane) or "")
		end
		if cwd == "" then
			return nil, "other payload is missing cwd"
		end

		if title == "" then
			title = shorten_command(cmd)
		end
	end

	return {
		mode = mode,
		cmd = cmd,
		cwd = cwd,
		title = title,
	}
end

local function notify(window, message)
	local text = trim(message)
	if text == "" then
		text = "unknown error"
	end

	if window and window.toast_notification then
		window:toast_notification(task_banner, text, nil, 4000)
	end

	wezterm.log_error(text)
end

local function select_target_pane(window, pane, request)
	local tab = pane and pane:tab() or nil
	if not tab then
		return nil, "unable to access current tab"
	end

	local choices = {}
	for _, item in ipairs(tab:panes_with_info()) do
		if item.is_active then
			goto continue
		end

		local target_pane = item.pane
		local pane_id = target_pane:pane_id()
		local process_name = basename(target_pane:get_foreground_process_name())
		local title = target_pane:get_title() or ""

		table.insert(choices, {
			id = tostring(pane_id),
			label = string.format(
				"Pane %d | %s | %s",
				pane_id,
				process_name ~= "" and process_name or "unknown process",
				title ~= "" and title or "no_title"
			),
		})

		::continue::
	end

	if #choices == 0 then
		return nil, "no other panes available in the current tab"
	end

	window:perform_action(
		act.InputSelector({
			title = "Select pane",
			description = "Choose the pane that should receive text",
			choices = choices,
			fuzzy = true,
			fuzzy_description = "Search by pane id, process, or title: ",
			action = wezterm.action_callback(function(inner_window, inner_pane, id, _label)
				if not id then
					return
				end

				local target_id = tonumber(id)
				if not target_id then
					notify(inner_window, "invalid target pane id")
					return
				end

				for _, info in ipairs(inner_pane:tab():panes_with_info()) do
					if info.pane:pane_id() == target_id then
						info.pane:paste(request.cmd)
						return
					end
				end

				notify(inner_window, "selected pane no longer exists")
			end),
		}),
		pane
	)

	return true
end

local function spawn_task_tab(window, pane, request)
	local mux_window = window:mux_window()
	if not mux_window then
		return nil, "unable to access mux window for task"
	end

	local script = "cd -- " .. shell_quote(request.cwd) .. " || exit 1\n" .. request.cmd
	local tab, _, _ = mux_window:spawn_tab({
		cwd = request.cwd,
		args = {
			shell,
			"-ilc",
			task_script(request.title, script),
		},
	})
	tab:set_title(request.title)
	tab:activate()
	return tab
end

function module.user_var_name()
	return user_var_name
end

function module.current_cwd(pane)
	return current_cwd(pane)
end

function module.notify(window, message)
	notify(window, message)
end

function module.format_tab_title(tab)
	local task_state = parse_task_state(tab.active_pane and tab.active_pane.title or nil)
	local title = default_title(tab)
	if task_state and title and title ~= "" then
		return format_task_tab_title(tab, task_state, title)
	end

	return format_default_tab_title(tab)
end

function module.dispatch(window, pane, request)
	local normalized, err = normalize_request(pane, request)
	if not normalized then
		return nil, err
	end

	if normalized.mode == "selector" then
		return select_target_pane(window, pane, normalized)
	end

	return spawn_task_tab(window, pane, normalized)
end

function module.setup()
	if state.is_setup then
		return
	end

	state.is_setup = true

	wezterm.on("format-tab-title", function(tab)
		return module.format_tab_title(tab)
	end)

	wezterm.on("user-var-changed", function(window, pane, name, value)
		if name ~= user_var_name then
			return
		end

		local request, err = parse_request(value)
		if not request then
			notify(window, err)
			return
		end

		local _, dispatch_err = module.dispatch(window, pane, request)
		if dispatch_err then
			notify(window, dispatch_err)
		end
	end)
end

return module
