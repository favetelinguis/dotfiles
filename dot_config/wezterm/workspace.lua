-- My custom wezterm workspace thing

local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local module = {}

local workspace_state = {
	current = nil,
	previous = nil,
}

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
	local tab, _, _ = mux_window:spawn_tab({
		cwd = cwd,
		args = args,
	})
	tab:set_title(name)
	tab:activate()
end

local function basename(path)
	if not path or path == "" then
		return nil
	end

	return path:match("([^/]+)/*$")
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

	if workspace_exists(workspace_state.previous) and workspace_state.previous ~= current then
		target = workspace_state.previous
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
	if workspace_state.current ~= current then
		if workspace_state.current and workspace_state.current ~= "" and workspace_state.current ~= current then
			workspace_state.previous = workspace_state.current
		end
		workspace_state.current = current
	end

	if window:leader_is_active() then
		window:set_left_status(" LEADER ")
	else
		window:set_left_status("")
	end

	local cells = {}
	local workspace = current
	if workspace and workspace ~= "" then
		table.insert(cells, "ws:" .. workspace)
	end

	local cwd_uri = pane:get_current_working_dir()
	local cwd_name = cwd_uri and basename(cwd_uri.file_path) or nil
	if cwd_name and cwd_name ~= "" then
		table.insert(cells, cwd_name)
	end

	table.insert(cells, wezterm.strftime("%Y-%m-%d %H:%M"))
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
					create_workspace_with_first_tab(window, pane, line)
				end
			end
		end),
	})
end

return module
