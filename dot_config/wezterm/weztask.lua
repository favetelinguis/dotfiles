local wezterm = require("wezterm")

local module = {}

local task_title_prefix = "weztask:"
local task_colors = {
	running = "#e0af68",
	failure = "#f7768e",
	success = "#9ece6a",
	text = "#15161e",
}
local shell = "/bin/zsh"
local task_banner = "WezTask"

local function trim(text)
	return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function default_title(tab)
	if tab.tab_title and #tab.tab_title > 0 then
		return tab.tab_title
	end

	return tab.active_pane and tab.active_pane.title or nil
end

local function parse_task_state(title)
	if type(title) ~= "string" then
		return nil
	end

	local state = title:match("^" .. task_title_prefix .. "([^:]+)$")
	if not state then
		return nil
	end

	if not task_colors[state] then
		return nil
	end

	return state
end

local function zoom_prefix(tab)
	return tab.active_pane.is_zoomed and "[Z] " or ""
end

local function format_default_tab_title(tab)
	return string.format(" %d: %s%s ", tab.tab_index + 1, zoom_prefix(tab), default_title(tab))
end

local function format_task_tab_title(tab, state, name)
	return {
		{ Background = { Color = task_colors[state] } },
		{ Foreground = { Color = task_colors.text } },
		{ Text = string.format(" %d: %s%s ", tab.tab_index + 1, zoom_prefix(tab), name) },
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

local function shell_quote(value)
	return "'" .. tostring(value):gsub("'", [["'"']]) .. "'"
end

local function title_escape(title)
	return string.format("\\033]2;%s\\007", title)
end

local function make_state_title(state)
	return string.format("%s%s", task_title_prefix, state)
end

local function current_cwd(pane)
	local cwd_url = pane and pane:get_current_working_dir() or nil
	return cwd_url and cwd_url.file_path or nil
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

local function run_child_process_in_dir(cwd, command)
	local script = "cd -- " .. shell_quote(cwd) .. " || exit 1\n" .. command
	local ok, stdout, stderr = wezterm.run_child_process({
		shell,
		"-lc",
		script,
	})

	return ok, trim(stdout), trim(stderr)
end

local function list_recipes(cwd)
	local ok, stdout, stderr = run_child_process_in_dir(cwd, "just -l")
	if not ok then
		return nil, stderr ~= "" and stderr or stdout ~= "" and stdout or "failed to run just -l"
	end

	local choices = {}
	for line in stdout:gmatch("([^\n]*)\n?") do
		local label = trim(line)
		if label ~= "" and label ~= "Available recipes:" then
			local recipe = label:match("^(%S+)")
			if recipe then
				table.insert(choices, {
					id = recipe,
					label = label,
				})
			end
		end
	end

	if #choices == 0 then
		return nil, "no recipes found"
	end

	return choices
end

local function is_missing_justfile_error(message)
	return type(message) == "string" and message:find("No justfile found", 1, true) ~= nil
end

function module.spawn_task_tab(window, pane, opts)
	local name = trim(opts.name)
	local command = trim(opts.command)
	local cwd = trim(opts.cwd)

	if name == "" then
		return nil, "task name is required"
	end
	if command == "" then
		return nil, "task command is required"
	end
	if cwd == "" then
		cwd = current_cwd(pane) or ""
	end
	if cwd == "" then
		return nil, "unable to determine current pane directory"
	end

	local mux_window = window:mux_window()
	if not mux_window then
		return nil, "unable to access mux window for task"
	end

	local script = "cd -- " .. shell_quote(cwd) .. " || exit 1\n" .. command
	local tab, _, _ = mux_window:spawn_tab({
		cwd = cwd,
		args = {
			shell,
			"-ilc",
			task_script(name, script),
		},
	})
	tab:set_title(name)
	tab:activate()
	return tab
end

local function spawn_recipe_tab(window, pane, recipe)
	local _, err = module.spawn_task_tab(window, pane, {
		name = recipe,
		command = "just " .. shell_quote(recipe),
	})
	if err then
		notify(window, err)
	end
end

function module.make_title(state, name)
	return string.format("%s%s:%s", task_title_prefix, state, name)
end

function module.format_tab_title(tab)
	local state = parse_task_state(tab.active_pane and tab.active_pane.title or nil)
	local title = default_title(tab)
	if state and title and title ~= "" then
		return format_task_tab_title(tab, state, title)
	end

	return format_default_tab_title(tab)
end

function module.setup()
	wezterm.on("format-tab-title", function(tab)
		return module.format_tab_title(tab)
	end)
end

function module.choose_recipe()
	return wezterm.action_callback(function(window, pane)
		local cwd = current_cwd(pane)
		if not cwd or cwd == "" then
			notify(window, "unable to determine current pane directory")
			return
		end

		local choices, err = list_recipes(cwd)
		if not choices then
			if is_missing_justfile_error(err) then
				return
			end
			notify(window, err)
			return
		end

		window:perform_action(
			wezterm.action.InputSelector({
				title = "Just Recipes",
				description = "Select a recipe from just -l",
				choices = choices,
				fuzzy = true,
				fuzzy_description = "Enter a recipe name: ",
				action = wezterm.action_callback(function(inner_window, inner_pane, id, _label)
					if not id then
						return
					end

					spawn_recipe_tab(inner_window, inner_pane, id)
				end),
			}),
			pane
		)
	end)
end

return module
