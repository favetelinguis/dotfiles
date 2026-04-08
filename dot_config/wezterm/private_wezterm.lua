require("scrollback")
local ws = require("workspace")
local projects = require("projects")
local weznotes = require("weznotes")

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local function split_nav(mode, key)
	local mods = mode == "resize" and "CTRL" or "META"

	return {
		key = key,
		mods = mods,
		action = wezterm.action_callback(function(window, pane)
			if is_vim(pane) then
				window:perform_action({
					SendKey = {
						key = key,
						mods = mods,
					},
				}, pane)
				return
			end

			if mode == "resize" then
				window:perform_action({
					AdjustPaneSize = { direction_keys[key], 3 },
				}, pane)
				return
			end

			window:perform_action({
				ActivatePaneDirection = direction_keys[key],
			}, pane)
		end),
	}
end

-- Color scheme from colors/Noctalia.toml
config.color_scheme = "tokyonight_night"

-- Font configuration
config.font = wezterm.font("JetBrains Mono")
config.font_size = 12.0
config.line_height = 1.2

-- Window configuration
config.window_padding = {
	left = 2,
	right = 2,
	top = 2,
	bottom = 2,
}

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false
config.show_tabs_in_tab_bar = true
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32
config.status_update_interval = 1000
config.colors = {
	tab_bar = {
		inactive_tab = { fg_color = "#c8d3f5", bg_color = "#292e42" },
		active_tab = { fg_color = "#15161e", bg_color = "#7aa2f7" },
	},
}

-- Cursor
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500

-- Window appearance
config.window_background_opacity = 1.0
config.window_close_confirmation = "NeverPrompt"
config.native_macos_fullscreen_mode = true
config.pane_focus_follows_mouse = true

-- config.default_prog = { "/usr/bin/nu", "-l" }
config.leader = {
	key = "Space",
	mods = "ALT",
	timeout_milliseconds = 1000,
}
config.launch_menu = {
	{
		label = "Nu shell",
		args = { "/usr/bin/nu", "-l" },
	},
	{
		label = "Lazygit",
		args = { "lazygit" },
	},
	{
		label = "btop",
		args = { "btop" },
	},
}

config.mouse_bindings = {
	-- Open URLs with CMD+Click
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "SUPER",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}

config.scrollback_lines = 100000

config.keys = {
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),
	split_nav("resize", "h"),
	split_nav("resize", "j"),
	split_nav("resize", "k"),
	split_nav("resize", "l"),
	{
		key = "e",
		mods = "LEADER",
		action = act.EmitEvent("trigger-vim-with-scrollback"),
	},
	{
		key = "i",
		mods = "SUPER",
		action = ws.prompt_for_workspace(),
	},
	{
		key = "n",
		mods = "SUPER",
		action = wezterm.action_callback(ws.toggle_workspace),
	},
	{
		key = "p",
		mods = "LEADER",
		action = act.ShowLauncher,
	},
	{
		key = "P",
		mods = "LEADER",
		action = act.ActivateCommandPalette,
	},
	{
		key = "f",
		mods = "SUPER",
		action = act.ShowLauncherArgs({
			flags = "FUZZY|WORKSPACES",
			title = "Workspace Switcher",
		}),
	},
	{
		key = "d",
		mods = "LEADER",
		action = act.SplitVertical({
			domain = "CurrentPaneDomain",
		}),
	},
	{
		key = "s",
		mods = "LEADER",
		action = act.SplitHorizontal({
			domain = "CurrentPaneDomain",
		}),
	},
	{
		key = "q",
		mods = "SUPER",
		action = act.CloseCurrentPane({ confirm = false }),
	},
	{
		key = "q",
		mods = "LEADER",
		action = act.CloseCurrentTab({ confirm = true }),
	},
	{
		key = "m",
		mods = "SUPER",
		action = act.TogglePaneZoomState,
	},
	{
		key = "p",
		mods = "SUPER",
		action = projects.choose_project(),
	},
	{
		key = "1",
		mods = "SUPER",
		action = act.ActivateTab(0),
	},
	{
		key = "2",
		mods = "SUPER",
		action = act.ActivateTab(1),
	},
	{
		key = "3",
		mods = "SUPER",
		action = act.ActivateTab(2),
	},
	{
		key = "4",
		mods = "SUPER",
		action = act.ActivateTab(3),
	},
	{
		key = "5",
		mods = "SUPER",
		action = act.ActivateTab(4),
	},
	{
		key = "6",
		mods = "SUPER",
		action = act.ActivateTab(5),
	},
	{
		key = "7",
		mods = "SUPER",
		action = wezterm.action_callback(function(window, pane)
			ws.activate_or_open_named_tab(window, pane, "K9s", { "k9s" })
		end),
	},
	{
		key = "8",
		mods = "SUPER",
		action = wezterm.action_callback(weznotes.open_or_activate_notes_tab),
	},
	{
		key = "9",
		mods = "SUPER",
		action = wezterm.action_callback(function(window, pane)
			ws.activate_or_open_named_tab(window, pane, "Git", { "lazygit" })
		end),
	},
	{
		key = "0",
		mods = "SUPER",
		action = wezterm.action_callback(function(window, pane)
			ws.activate_or_open_named_tab(window, pane, "Dash", { "gh", "dash" })
		end),
	},
}

return config
