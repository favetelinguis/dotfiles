local api = vim.api

local M = {}

local defaults = {
	keys = {
		next = "n",
		prev = "p",
		delete = "d",
	},
	mappings = {
		next = "ga",
		prev = nil,
	},
	path_style = "tail_dir",
	exclude_filetypes = {},
	float = {
		relative = "editor",
		border = "rounded",
		max_height = 8,
		max_width = 0.5,
		row_offset = -1,
		col_offset = -2,
	},
	highlights = {
		current = "Visual",
		adjacent = "Comment",
		background = "NormalFloat",
		border = "FloatBorder",
	},
}

local state = {
	active = false,
	buffers = {},
	focus = nil,
	win = nil,
	buf = nil,
	source_win = nil,
	prev_lazyredraw = nil,
	ns = api.nvim_create_namespace("flipb"),
}

M.opts = vim.deepcopy(defaults)

local mru_counter = 0
local mru_order = {} -- bufnr -> sequence number (higher = more recently used)
local window_views = {} -- winid -> bufnr -> winsaveview()

local function mru_touch(bufnr)
	mru_counter = mru_counter + 1
	mru_order[bufnr] = mru_counter
end

local function option_width(value, total)
	if type(value) == "number" and value > 0 and value < 1 then
		return math.max(1, math.floor(total * value))
	end
	return math.max(1, value)
end

local function path_style(style, path)
	if path == "" then
		return "[No Name]"
	end

	local absolute = vim.fn.fnamemodify(path, ":p")

	if type(style) == "function" then
		return style(absolute)
	end
	if style == "absolute" then
		return absolute
	end
	if style == "relative" then
		return vim.fn.fnamemodify(absolute, ":.")
	end
	if style == "tail" then
		return vim.fn.fnamemodify(absolute, ":t")
	end
	if style == "tail_dir" then
		local tail = vim.fn.fnamemodify(absolute, ":t")
		local dir = vim.fn.fnamemodify(absolute, ":h:t")
		if dir == "" or dir == "." then
			return tail
		end
		return string.format("%s/%s", dir, tail)
	end
	if style == "short_relative" then
		local relative = vim.fn.fnamemodify(absolute, ":.")
		local parts = vim.split(relative, "/", { plain = true, trimempty = true })
		if #parts <= 1 then
			return relative
		end
		for i = 1, #parts - 1 do
			parts[i] = parts[i]:sub(1, 1)
		end
		return table.concat(parts, "/")
	end

	return vim.fn.fnamemodify(absolute, ":.")
end

local function current_buf_index(buffers)
	local current = api.nvim_get_current_buf()
	for i, entry in ipairs(buffers) do
		if entry.bufnr == current then
			return i
		end
	end
	return nil
end

local function is_switchable(bufnr)
	if not api.nvim_buf_is_valid(bufnr) then
		return false
	end
	if vim.fn.buflisted(bufnr) ~= 1 then
		return false
	end
	if vim.bo[bufnr].buftype ~= "" then
		return false
	end
	if vim.tbl_contains(M.opts.exclude_filetypes, vim.bo[bufnr].filetype) then
		return false
	end
	return true
end

local function collect_buffers()
	local buffers = {}

	for _, bufnr in ipairs(api.nvim_list_bufs()) do
		if is_switchable(bufnr) then
			if not mru_order[bufnr] then
				local info = vim.fn.getbufinfo(bufnr)[1] or {}
				mru_order[bufnr] = info.lastused or 0
			end
			table.insert(buffers, {
				bufnr = bufnr,
				lastused = mru_order[bufnr],
				path = path_style(M.opts.path_style, api.nvim_buf_get_name(bufnr)),
			})
		end
	end

	table.sort(buffers, function(a, b)
		if a.lastused == b.lastused then
			return a.bufnr < b.bufnr
		end
		return a.lastused > b.lastused
	end)

	return buffers
end

local function close_window()
	if state.win and api.nvim_win_is_valid(state.win) then
		pcall(api.nvim_win_close, state.win, true)
	end
	if state.prev_lazyredraw ~= nil then
		vim.o.lazyredraw = state.prev_lazyredraw
	end
	state.active = false
	state.win = nil
	state.focus = nil
	state.source_win = nil
	state.prev_lazyredraw = nil
end

local function ensure_float_buf()
	if state.buf and api.nvim_buf_is_valid(state.buf) then
		return state.buf
	end

	state.buf = api.nvim_create_buf(false, true)
	vim.bo[state.buf].buftype = "nofile"
	vim.bo[state.buf].bufhidden = "wipe"
	vim.bo[state.buf].swapfile = false
	vim.bo[state.buf].modifiable = false
	return state.buf
end

local function truncate_to_width(text, width)
	if vim.fn.strdisplaywidth(text) <= width then
		return text
	end

	if width <= 1 then
		return "…"
	end

	local target = width - 1
	while vim.fn.strdisplaywidth(text) > target and #text > 0 do
		text = text:sub(1, -2)
	end
	return text .. "…"
end

local function visible_slice()
	local total = #state.buffers
	local height = math.min(total, M.opts.float.max_height)
	local start = math.max(1, state.focus - math.floor(height / 2))
	start = math.min(start, math.max(1, total - height + 1))
	return start, start + height - 1
end

local function render()
	if not state.active or not state.focus or #state.buffers == 0 then
		close_window()
		return
	end

	local buf = ensure_float_buf()
	local start_idx, end_idx = visible_slice()
	local entries = {}
	local max_width = 0

	for i = start_idx, end_idx do
		local line = state.buffers[i].path
		max_width = math.max(max_width, vim.fn.strdisplaywidth(line))
		entries[#entries + 1] = line
	end

	local editor_width = vim.o.columns
	local width = math.min(option_width(M.opts.float.max_width, editor_width), max_width)
	width = math.max(1, width)

	for i, line in ipairs(entries) do
		entries[i] = truncate_to_width(line, width)
	end

	vim.bo[buf].modifiable = true
	api.nvim_buf_set_lines(buf, 0, -1, false, entries)
	vim.bo[buf].modifiable = false
	api.nvim_buf_clear_namespace(buf, state.ns, 0, -1)

	for line_nr = 1, #entries do
		local highlight = (start_idx + line_nr - 1 == state.focus) and M.opts.highlights.current
			or M.opts.highlights.adjacent
		api.nvim_buf_add_highlight(buf, state.ns, highlight, line_nr - 1, 0, -1)
	end

	local height = #entries
	local row = vim.o.lines - vim.o.cmdheight - height - 2 + M.opts.float.row_offset
	local col = vim.o.columns - width - 2 + M.opts.float.col_offset
	row = math.max(0, row)
	col = math.max(0, col)
	local win_opts = {
		relative = M.opts.float.relative,
		style = "minimal",
		border = M.opts.float.border,
		anchor = "NW",
		focusable = false,
		width = width,
		height = height,
		row = row,
		col = col,
	}

	if state.win and api.nvim_win_is_valid(state.win) then
		api.nvim_win_set_config(state.win, win_opts)
	else
		state.win = api.nvim_open_win(buf, false, win_opts)
	end

	api.nvim_set_option_value(
		"winhl",
		string.format("NormalFloat:%s,FloatBorder:%s", M.opts.highlights.background, M.opts.highlights.border),
		{ win = state.win }
	)
end

local function refresh_ui()
	if state.source_win and api.nvim_win_is_valid(state.source_win) then
		pcall(api.nvim__redraw, {
			win = state.source_win,
			valid = false,
			cursor = true,
		})
	end
	if state.win and api.nvim_win_is_valid(state.win) then
		pcall(api.nvim__redraw, {
			win = state.win,
			valid = false,
		})
	end
	pcall(api.nvim__redraw, { flush = true })
	pcall(vim.cmd, "redraw!")
end

local function source_win_call(fn)
	if not state.source_win or not api.nvim_win_is_valid(state.source_win) then
		return nil
	end
	return api.nvim_win_call(state.source_win, fn)
end

local function views_for_win(winid)
	if not window_views[winid] then
		window_views[winid] = {}
	end
	return window_views[winid]
end

local function save_view_for_win(winid, bufnr)
	if not winid or not api.nvim_win_is_valid(winid) or not bufnr or not api.nvim_buf_is_valid(bufnr) then
		return
	end

	local ok, view = pcall(api.nvim_win_call, winid, function()
		return vim.fn.winsaveview()
	end)
	if ok and view then
		views_for_win(winid)[bufnr] = view
	end
end

local function save_current_view()
	local bufnr = state.source_win
		and api.nvim_win_is_valid(state.source_win)
		and api.nvim_win_get_buf(state.source_win)
	save_view_for_win(state.source_win, bufnr)
end

local function restore_view(bufnr)
	local cached = views_for_win(state.source_win)[bufnr]

	local ok = pcall(source_win_call, function()
		if cached then
			vim.fn.winrestview(cached)
			return
		end

		local view = vim.fn.winsaveview()
		local mark = api.nvim_buf_get_mark(bufnr, '"')
		local line_count = api.nvim_buf_line_count(bufnr)
		local row = math.min(math.max(mark[1], 1), math.max(line_count, 1))
		local col = math.max(mark[2], 0)

		if mark[1] > 0 and view.lnum ~= row then
			pcall(api.nvim_win_set_cursor, state.source_win, { row, col })
			view = vim.fn.winsaveview()
		end

		views_for_win(state.source_win)[bufnr] = view
		vim.fn.winrestview(view)
	end)

	return ok
end

local function load_focus()
	if not state.source_win or not api.nvim_win_is_valid(state.source_win) then
		return false
	end

	local target = state.buffers[state.focus]
	if not target or not api.nvim_buf_is_valid(target.bufnr) then
		return false
	end

	save_current_view()
	api.nvim_win_set_buf(state.source_win, target.bufnr)
	return restore_view(target.bufnr)
end

local function start_selector(direction)
	state.buffers = collect_buffers()
	if #state.buffers == 0 then
		vim.notify("flipb: No switchable buffers", vim.log.levels.INFO)
		return false
	end

	state.source_win = api.nvim_get_current_win()
	save_current_view()

	local current_index = current_buf_index(state.buffers)
	if not current_index then
		current_index = 1
	end

	if direction == "next" then
		state.focus = current_index % #state.buffers + 1
	else
		state.focus = (current_index - 2) % #state.buffers + 1
	end

	return load_focus()
end

local function move_focus(direction)
	if #state.buffers == 0 then
		return false
	end

	if direction == "next" then
		state.focus = state.focus % #state.buffers + 1
	else
		state.focus = (state.focus - 2) % #state.buffers + 1
	end

	return load_focus()
end

local function refresh_after_delete()
	local old_focus = state.focus
	state.buffers = collect_buffers()
	if #state.buffers == 0 then
		close_window()
		return false
	end

	local current_index = current_buf_index(state.buffers)
	state.focus = current_index or math.min(old_focus or 1, #state.buffers)
	if not load_focus() then
		close_window()
		return false
	end
	render()
	return true
end

local function selector_key_matches(input, configured)
	local keycode = api.nvim_replace_termcodes(configured, true, true, true)
	return input == configured or input == keycode
end

function M.get_input()
	return vim.fn.getcharstr()
end

function M.forward_input(key)
	return api.nvim_input(key)
end

function M.select(direction)
	if direction ~= "next" and direction ~= "prev" then
		error("flipb.select(direction): direction must be 'next' or 'prev'")
	end

	state.prev_lazyredraw = vim.o.lazyredraw
	vim.o.lazyredraw = false
	state.active = true
	if not start_selector(direction) then
		close_window()
		return
	end

	render()
	refresh_ui()

	while state.active do
		local ok, key = pcall(M.get_input)
		if not ok then
			mru_touch(api.nvim_get_current_buf())
			close_window()
			return
		end

		if selector_key_matches(key, M.opts.keys.next) then
			if move_focus("next") then
				render()
				refresh_ui()
			else
				close_window()
				return
			end
		elseif selector_key_matches(key, M.opts.keys.prev) then
			if move_focus("prev") then
				render()
				refresh_ui()
			else
				close_window()
				return
			end
		elseif selector_key_matches(key, M.opts.keys.delete) then
			local target = api.nvim_get_current_buf()
			local deleted = pcall(api.nvim_buf_delete, target, {})
			if deleted then
				mru_order[target] = nil
				if not refresh_after_delete() then
					return
				end
				refresh_ui()
			else
				vim.notify("flipb: Failed to delete buffer", vim.log.levels.WARN)
			end
		else
			mru_touch(api.nvim_get_current_buf())
			close_window()
			pcall(M.forward_input, key)
			return
		end
	end
end

function M.setup(opts)
	M.opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

	for _, bufnr in ipairs(api.nvim_list_bufs()) do
		if is_switchable(bufnr) then
			local info = vim.fn.getbufinfo(bufnr)[1] or {}
			local ts = info.lastused or 0
			mru_order[bufnr] = ts
			if ts > mru_counter then
				mru_counter = ts
			end
		end
	end

	local group = api.nvim_create_augroup("flipb_mru", { clear = true })
	api.nvim_create_autocmd("BufEnter", {
		group = group,
		callback = function(ev)
			if not state.active and is_switchable(ev.buf) then
				mru_touch(ev.buf)
			end
		end,
	})
	api.nvim_create_autocmd("BufLeave", {
		group = group,
		callback = function(ev)
			if is_switchable(ev.buf) then
				save_view_for_win(api.nvim_get_current_win(), ev.buf)
			end
		end,
	})
	api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(ev)
			mru_order[ev.buf] = nil
			for _, views in pairs(window_views) do
				views[ev.buf] = nil
			end
		end,
	})
	api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function(ev)
			window_views[tonumber(ev.match)] = nil
		end,
	})

	api.nvim_create_user_command("FlipbNext", function()
		require("flipb").select("next")
	end, { nargs = 0, desc = "Flipb next MRU buffer" })

	api.nvim_create_user_command("FlipbPrev", function()
		require("flipb").select("prev")
	end, { nargs = 0, desc = "Flipb previous MRU buffer" })

	if M.opts.mappings.next then
		vim.keymap.set({ "n", "v" }, M.opts.mappings.next, function()
			require("flipb").select("next")
		end, { desc = "Flipb next MRU buffer" })
	end

	if M.opts.mappings.prev then
		vim.keymap.set({ "n", "v" }, M.opts.mappings.prev, function()
			require("flipb").select("prev")
		end, { desc = "Flipb previous MRU buffer" })
	end
end

return M
