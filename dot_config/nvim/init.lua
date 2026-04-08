require("config.options")
require("config.keymaps")
require("java")

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

require("broot").setup()
require("weznotes").setup()

require("config.lazy")
