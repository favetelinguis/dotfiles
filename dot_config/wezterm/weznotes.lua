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

local function file_exists(path)
	local file = io.open(path, "r")
	if not file then
		return false
	end

	file:close()
	return true
end

local function ensure_file(path)
	if file_exists(path) then
		return true
	end

	local err
	local file
	file, err = io.open(path, "w")
	if not file then
		return nil, err or ("unable to create " .. path)
	end
	file:close()
	return true
end

local function parent_dir(path)
	local last_sep = nil
	local start = 1

	while true do
		local index = string.find(path, path_sep, start, true)
		if not index then
			break
		end

		last_sep = index
		start = index + 1
	end

	if not last_sep then
		return nil
	end

	return path:sub(1, last_sep - 1)
end

function module.notes_repo_dir()
	return join_path(xdg_data_home(), "weznotes")
end

function module.default_note_relative_path()
	return join_path("references", "current_work.md")
end

function module.default_note_path()
	return join_path(module.notes_repo_dir(), module.default_note_relative_path())
end

local function ensure_default_note(repo)
	local relative_path = module.default_note_relative_path()
	local note_path = module.default_note_path()
	local parent_path = parent_dir(note_path)
	if parent_path then
		local dir_ok, dir_err = ensure_directory(parent_path)
		if not dir_ok then
			return nil, dir_err
		end
	end

	if file_exists(note_path) then
		return note_path
	end

	local file_ok, file_err = ensure_file(note_path)
	if not file_ok then
		return nil, file_err
	end

	local add_ok, add_err = run_child_process({ "git", "-C", repo, "add", "--", relative_path })
	if not add_ok then
		return nil, add_err
	end

	local commit_ok, commit_err = run_child_process({
		"git",
		"-C",
		repo,
		"commit",
		"--no-verify",
		"-m",
		"Create note " .. relative_path,
		"--",
		relative_path,
	})
	if not commit_ok then
		return nil, commit_err
	end

	return note_path
end

function module.ensure_repo()
	local repo = module.notes_repo_dir()
	local ok, err = ensure_directory(repo)
	if not ok then
		return nil, err
	end

	if not is_git_repo(repo) then
		local init_ok, init_err = run_child_process({ "git", "-C", repo, "init" })
		if not init_ok then
			return nil, init_err
		end
	end

	local note_path, note_err = ensure_default_note(repo)
	if not note_path then
		return nil, note_err
	end

	return repo
end

function module.open_or_activate_notes_tab(window, _pane)
	local repo, err = module.ensure_repo()
	if not repo then
		notify(window, err)
		return
	end

	local note_path = module.default_note_path()

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
			WEZNOTES_FILE = note_path,
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
