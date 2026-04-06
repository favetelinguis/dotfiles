require("config.options")
require("config.keymaps")

require("flipb").setup({
	mappings = {
		next = "ga",
		prev = nil,
	},
	keys = {
		next = "j",
		prev = "k",
	},
})

require("config.lazy")
