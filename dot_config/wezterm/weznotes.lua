local wezterm = require("wezterm")

local module = {}

local path_sep = package.config:sub(1, 1)

local function join_path(...)
	return table.concat({ ... }, path_sep)
end

local function trim(text)
	return (text or ""):gsub("%s+$", "")
end

local function xdg_data_home()
	local value = os.getenv("XDG_DATA_HOME")
	if value and value ~= "" then
		return value
	end

	return join_path(wezterm.home_dir, ".local", "share")
end

local function notify(window, message)
	if window and window.toast_notification then
		window:toast_notification("WezNotes", message, nil, 4000)
	end

	wezterm.log_error(message)
end

local function run_child_process(args)
	local ok, stdout, stderr = wezterm.run_child_process(args)
	stdout = trim(stdout)
	stderr = trim(stderr)
	if ok then
		return true, stdout
	end

	return false, stderr ~= "" and stderr or stdout ~= "" and stdout or ("command failed: " .. table.concat(args, " "))
end

local function ensure_directory(path)
	local ok, err = run_child_process({ "mkdir", "-p", path })
	if not ok then
		return nil, err
	end

	return true
end

local function is_git_repo(path)
	local ok = run_child_process({ "git", "-C", path, "rev-parse", "--is-inside-work-tree" })
	return ok
end

local function ensure_file(path)
	local file = io.open(path, "r")
	if file then
		file:close()
		return true
	end

	local err
	file, err = io.open(path, "w")
	if not file then
		return nil, err or ("unable to create " .. path)
	end
	file:close()
	return true
end

function module.notes_repo_dir()
	return join_path(xdg_data_home(), "weznotes")
end

function module.todo_path()
	return join_path(module.notes_repo_dir(), "TODO.md")
end

function module.ensure_repo()
	local repo = module.notes_repo_dir()
	local ok, err = ensure_directory(repo)
	if not ok then
		return nil, err
	end

	local todo_path = module.todo_path()
	local repo_exists = is_git_repo(repo)

	local file_ok, file_err = ensure_file(todo_path)
	if not file_ok then
		return nil, file_err
	end

	if repo_exists then
		return repo
	end

	local init_ok, init_err = run_child_process({ "git", "-C", repo, "init" })
	if not init_ok then
		return nil, init_err
	end

	return repo
end

function module.open_or_activate_notes_tab(window, _pane)
	local repo, err = module.ensure_repo()
	if not repo then
		notify(window, err)
		return
	end

	local todo_path = module.todo_path()

	local mux_window = window:mux_window()
	if not mux_window then
		notify(window, "unable to access mux window for notes tab")
		return
	end

	for _, item in ipairs(mux_window:tabs_with_info()) do
		if item.tab:get_title() == "Notes" then
			item.tab:activate()
			return
		end
	end

	local ok, tab = pcall(mux_window.spawn_tab, mux_window, {
		cwd = repo,
		set_environment_variables = {
			WEZNOTES_DIR = repo,
			WEZNOTES_FILE = todo_path,
		},
		args = {
			"/bin/zsh",
			"-il",
			"-c",
			'cd "$WEZNOTES_DIR" || exit 1; exec nvim "$WEZNOTES_FILE"',
		},
	})

	if not ok then
		notify(window, tab)
		return
	end

	if not tab then
		notify(window, "notes tab did not return a tab handle")
		return
	end

	tab:set_title("Notes")
	tab:activate()
end

return module
