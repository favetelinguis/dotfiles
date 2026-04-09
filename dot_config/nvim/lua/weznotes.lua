local M = {}

local path_sep = package.config:sub(1, 1)
local group = vim.api.nvim_create_augroup("weznotes", { clear = true })
local state = {
	pending = {},
	in_flight = {},
	is_setup = false,
}

local function xdg_data_home()
	local value = vim.env.XDG_DATA_HOME
	if value and value ~= "" then
		return value
	end

	return vim.fs.joinpath(vim.uv.os_homedir(), ".local", "share")
end

local function repo_dir()
	return vim.fs.normalize(vim.fs.joinpath(xdg_data_home(), "weznotes"))
end

local function normalize(path)
	return vim.fs.normalize(path)
end

local function relpath(path)
	local repo = repo_dir()
	local normalized = normalize(path)
	local prefix = repo .. path_sep

	if normalized == repo then
		return "."
	end

	if normalized:sub(1, #prefix) == prefix then
		return normalized:sub(#prefix + 1)
	end

	return nil
end

local function note_path(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		return nil
	end

	return normalize(name)
end

local function is_notes_buffer(bufnr)
	local path = note_path(bufnr)
	if not path then
		return false
	end

	return relpath(path) ~= nil
end

local function run_git(args)
	local result = vim.system(vim.list_extend({ "git", "-C", repo_dir() }, args), { text = true }):wait()
	if result.code == 0 then
		return result
	end

	local stderr = vim.trim(result.stderr or "")
	local stdout = vim.trim(result.stdout or "")
	error(stderr ~= "" and stderr or stdout ~= "" and stdout or ("git command failed: " .. table.concat(args, " ")))
end

local function git_result(args)
	local result = vim.system(vim.list_extend({ "git", "-C", repo_dir() }, args), { text = true }):wait()
	return result.code, vim.trim(result.stdout or ""), vim.trim(result.stderr or "")
end

local function note_label(rel_note)
	return rel_note == "." and "TODO.md" or rel_note
end

local function commit_message(rel_note)
	return string.format("notes: update %s %s", note_label(rel_note), os.date("%Y-%m-%d %H:%M:%S"))
end

local function commit_note(rel_note)
	if state.in_flight[rel_note] then
		return
	end

	state.in_flight[rel_note] = true

	local ok, err = pcall(function()
		local code, stdout, stderr = git_result({ "status", "--porcelain", "--", rel_note })
		if code ~= 0 then
			error(stderr ~= "" and stderr or stdout)
		end

		if stdout == "" then
			state.pending[rel_note] = nil
			return
		end

		run_git({ "add", "-A", "--", rel_note })

		local diff_code, _, diff_stderr = git_result({ "diff", "--cached", "--quiet", "--", rel_note })
		if diff_code == 0 then
			state.pending[rel_note] = nil
			return
		end

		if diff_code ~= 1 then
			error(diff_stderr ~= "" and diff_stderr or "unable to inspect staged notes changes")
		end

		run_git({ "commit", "--no-verify", "-m", commit_message(rel_note), "--", rel_note })
		state.pending[rel_note] = nil
	end)

	state.in_flight[rel_note] = nil

	if not ok then
		vim.notify(err, vim.log.levels.ERROR, { title = "weznotes" })
		error(err)
	end
end

local function mark_pending(bufnr)
	if not is_notes_buffer(bufnr) then
		return
	end

	local path = note_path(bufnr)
	local relative = path and relpath(path)
	if relative then
		state.pending[relative] = true
	end
end

local function commit_buffer(bufnr)
	if not is_notes_buffer(bufnr) then
		return
	end

	local path = note_path(bufnr)
	local relative = path and relpath(path)
	if not relative or not state.pending[relative] then
		return
	end

	if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].modified then
		error("weznotes: save or discard note changes before closing " .. note_label(relative))
	end

	commit_note(relative)
end

local function commit_pending_on_exit()
	for bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(bufnr) and is_notes_buffer(bufnr) and vim.bo[bufnr].modified then
			local path = note_path(bufnr)
			local relative = path and relpath(path)
			error("weznotes: save or discard note changes before exiting Neovim: " .. note_label(relative or "."))
		end
	end

	local pending = vim.tbl_keys(state.pending)
	table.sort(pending)

	for _, relative in ipairs(pending) do
		commit_note(relative)
	end
end

function M.notes_repo_dir()
	return repo_dir()
end

function M.setup()
	if state.is_setup then
		return
	end

	state.is_setup = true

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		callback = function(args)
			mark_pending(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete" }, {
		group = group,
		callback = function(args)
			commit_buffer(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			commit_pending_on_exit()
		end,
	})
end

return M
