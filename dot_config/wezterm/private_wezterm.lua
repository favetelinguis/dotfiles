require("scrollback")
local ws = require("workspace")
local projects = require("projects")

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- Color scheme from colors/Noctalia.toml
config.color_scheme = "tokyonight_night"

-- Font configuration
config.font = wezterm.font("JetBrains Mono")
config.font_size = 11.0
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
		active_tab = { fg_color = "#6c7086", bg_color = "#74c7ec" },
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

config.default_prog = { "/usr/bin/nu", "-l" }
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
		key = "h",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "j",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Down"),
	},
	{
		key = "k",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "l",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Right"),
	},
	{
		key = "H",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "J",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Down", 5 }),
	},
	{
		key = "K",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Up", 5 }),
	},
	{
		key = "L",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Right", 5 }),
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
			action = act.ActivateTab(6),
		},
			{
				key = "8",
				mods = "SUPER",
				action = wezterm.action_callback(function(window, pane)
					ws.activate_or_open_named_tab(window, pane, "K9s", { "k9s" })
				end),
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
