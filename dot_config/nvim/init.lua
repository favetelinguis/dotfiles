require("config.options")
require("config.keymaps")
require("java")

require("flipb").setup({
	mappings = {
		next = "ga",
		prev = nil,
	},
	keys = {
		next = "n",
		prev = "p",
	},
})

require("broot").setup()
require("other").setup()
require("repl").setup()
require("ai").setup()
require("weznotes").setup()

require("config.lazy")
