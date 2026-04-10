local wezterm = require("wezterm")
local other = require("other")

local module = {}

local shell = "/bin/zsh"

local function trim(text)
	return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function shell_quote(value)
	return "'" .. tostring(value):gsub("'", [["'"']]) .. "'"
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

local function dispatch_recipe(window, pane, cwd, recipe)
	local _, err = other.dispatch(window, pane, {
		mode = "tab",
		cwd = cwd,
		cmd = "just " .. shell_quote(recipe),
		title = recipe,
	})
	if err then
		other.notify(window, err)
	end
end

function module.choose_recipe()
	return wezterm.action_callback(function(window, pane)
		local cwd = other.current_cwd(pane)
		if not cwd or cwd == "" then
			other.notify(window, "unable to determine current pane directory")
			return
		end

		local choices, err = list_recipes(cwd)
		if not choices then
			if is_missing_justfile_error(err) then
				return
			end
			other.notify(window, err)
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

					dispatch_recipe(inner_window, inner_pane, cwd, id)
				end),
			}),
			pane
		)
	end)
end

return module
