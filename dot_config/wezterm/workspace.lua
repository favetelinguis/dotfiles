-- My custom wezterm workspace thing

local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local module = {}

-- Avoid nested tables in wezterm.GLOBAL.
-- GLOBAL values are special proxy objects across reloads, so flat primitive keys
-- are more reliable than reading/modifying nested table state.
local workspace_current_key = "workspace.current"
local workspace_previous_key = "workspace.previous"

local function workspace_current()
	return wezterm.GLOBAL[workspace_current_key]
end

local function workspace_previous()
	return wezterm.GLOBAL[workspace_previous_key]
end

local function set_workspace_history(current, previous)
	wezterm.GLOBAL[workspace_current_key] = current
	wezterm.GLOBAL[workspace_previous_key] = previous
end

local function format_status_timestamp()
	local month = tonumber(wezterm.strftime("%m"))
	local week = tonumber(wezterm.strftime("%V"))
	local day = tonumber(wezterm.strftime("%d"))

	if not month or not week or not day then
		return wezterm.strftime("%H:%M")
	end

	return string.format("M%d W%d D%d %s", month, week, day, wezterm.strftime("%H:%M"))
end

local function wrap_args_with_cwd(cwd, args)
	if not cwd or cwd == "" or not args or #args == 0 then
		return args, nil
	end

	local wrapped = {
		"/bin/zsh",
		"-il",
		"-c",
		'cd "$WEZTERM_TAB_CWD" || exit 1; exec "$@"',
		"spawn",
	}

	for _, arg in ipairs(args) do
		table.insert(wrapped, arg)
	end

	return wrapped, {
		WEZTERM_TAB_CWD = cwd,
	}
end

function module.activate_or_open_named_tab(window, pane, name, args)
	local mux_window = window:mux_window()
	if not mux_window then
		return
	end

	for _, item in ipairs(mux_window:tabs_with_info()) do
		if item.tab:get_title() == name then
			item.tab:activate()
			return
		end
	end

	local cwd_url = pane:get_current_working_dir()
	local cwd = cwd_url and cwd_url.file_path or nil
	local spawn_args, spawn_env = wrap_args_with_cwd(cwd, args)
	local tab, _, _ = mux_window:spawn_tab({
		cwd = cwd,
		args = spawn_args,
		set_environment_variables = spawn_env,
	})
	tab:set_title(name)
	tab:activate()
end

local function workspace_exists(name)
	if not name or name == "" then
		return false
	end

	for _, workspace in ipairs(mux.get_workspace_names()) do
		if workspace == name then
			return true
		end
	end

	return false
end

local function current_cwd(pane)
	local cwd_url = pane and pane:get_current_working_dir() or nil
	return cwd_url and cwd_url.file_path or nil
end

local function create_window_with_first_tab_title_one(opts)
	local tab, _, _ = mux.spawn_window(opts or {})
	tab:set_title("1")
	return tab
end

function module.create_workspace_with_first_tab(window, pane, name)
	create_window_with_first_tab_title_one({
		workspace = name,
		cwd = current_cwd(pane),
	})
	mux.set_active_workspace(name)
end

function module.spawn_window_with_first_tab(window, pane)
	create_window_with_first_tab_title_one({
		workspace = window:active_workspace(),
		cwd = current_cwd(pane),
	})
end

wezterm.on("gui-startup", function(cmd)
	create_window_with_first_tab_title_one(cmd or {})
end)

function module.toggle_workspace(window, pane)
	local current = window:active_workspace()
	local target = nil
	local previous = workspace_previous()

	if workspace_exists(previous) and previous ~= current then
		target = previous
	else
		local workspaces = mux.get_workspace_names()
		table.sort(workspaces)
		for _, workspace in ipairs(workspaces) do
			if workspace ~= current then
				target = workspace
				break
			end
		end
	end

	if target then
		window:perform_action(
			act.SwitchToWorkspace({
				name = target,
			}),
			pane
		)
	end
end

wezterm.on("update-status", function(window, pane)
	local current = window:active_workspace()
	local saved_current = workspace_current()
	local saved_previous = workspace_previous()
	if saved_current ~= current then
		if saved_current and saved_current ~= "" then
			saved_previous = saved_current
		end
		set_workspace_history(current, saved_previous)
	end

	if window:leader_is_active() then
		window:set_left_status(" LEADER ")
	else
		window:set_left_status("")
	end

	local cells = {}
	local workspace = current
	if workspace and workspace ~= "" then
		table.insert(cells, workspace)
	end

	table.insert(cells, format_status_timestamp())
	window:set_right_status(table.concat(cells, " | "))
end)

function module.prompt_for_workspace()
	return act.PromptInputLine({
		description = "Enter name for new workspace",
		action = wezterm.action_callback(function(window, pane, line)
			if line and line ~= "" then
				if workspace_exists(line) then
					window:perform_action(
						act.SwitchToWorkspace({
							name = line,
						}),
						pane
					)
				else
					module.create_workspace_with_first_tab(window, pane, line)
				end
			end
		end),
	})
end

return module
