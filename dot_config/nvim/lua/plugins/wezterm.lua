return {
	"folke/lazydev.nvim",
	ft = "lua",
	dependencies = { "DrKJeff16/wezterm-types" },
	opts = {
		library = {
			-- Other library configs...
			{ path = "wezterm-types", mods = { "wezterm" } },
		},
	},
}
