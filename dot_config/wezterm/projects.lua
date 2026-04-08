local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

local fd = "fd"
local project_folder = "repos"

local function display_path(path)
	local marker = "/" .. project_folder .. "/"
	local start_idx = path:find(marker, 1, true)
	if not start_idx then
		return path
	end

	return path:sub(start_idx + 1)
end

local function basename(path)
	if not path or path == "" then
		return nil
	end

	return path:match("([^/]+)/*$")
end

local function list_projects()
	local projects = {}
	local success, stdout, stderr = wezterm.run_child_process({
		fd,
		"-HI",
		"^.git$",
		"--max-depth=4",
		"--prune",
		os.getenv("HOME") .. "/" .. project_folder,
	})

	if not success then
		wezterm.log_error("Failed to run fd: " .. stderr)
		return {}
	end

	for line in stdout:gmatch("([^\n]*)\n?") do
		local project = line:gsub("/.git.*$", "")
		table.insert(projects, {
			label = tostring(display_path(project)),
			id = tostring(project),
		})
	end
	return projects
end

function M.choose_project()
	local projects = list_projects()
	local choices = {}
	for _, project in ipairs(projects) do
		table.insert(choices, { id = project.id, label = project.label })
	end
	table.sort(choices, function(a, b)
		return a.label < b.label
	end)
	return wezterm.action.InputSelector({
		title = "Projects",
		description = "Project selector",
		choices = choices,
		fuzzy = true,
		fuzzy_description = "Enter a project name: ",
		action = wezterm.action_callback(function(window, pane, id, _label)
			if not id then
				return
			end

			local tab_name = basename(id)
			if not tab_name then
				return
			end

			local mux_window = window:mux_window()
			if not mux_window then
				return
			end

			for _, item in ipairs(mux_window:tabs_with_info()) do
				if item.tab:get_title() == tab_name then
					item.tab:activate()
					return
				end
			end

			local tab, _, _ = mux_window:spawn_tab({
				cwd = id,
				set_environment_variables = {
					WEZTERM_PROJECT_ROOT = id,
				},
				args = { "/bin/zsh", "-il", "-c", "cd $WEZTERM_PROJECT_ROOT; br" },
			})
			tab:set_title(tab_name)
			tab:activate()
		end),
	})
end

return M
