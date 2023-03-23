require("telescope").setup {
	defaults = {
		initial_mode = 'normal',
	},
  extensions = {
    file_browser = {
      -- disables netrw and use telescope-file-browser in its place
      hijack_netrw = true,
    },
  },
}

local builtin = require('telescope.builtin')
vim.keymap.set('n', 'ff', builtin.find_files, {})
vim.keymap.set('n', 'fg', builtin.live_grep, {})
vim.keymap.set('n', 'fs', builtin.grep_string, {})
vim.keymap.set('n', 'fb', builtin.buffers, {})
vim.keymap.set('n', 'fh', builtin.help_tags, {})
vim.keymap.set('n', 'fm', builtin.marks, {})
vim.keymap.set('n', 'fq', builtin.loclist, {})

-- For file browser telescope
require("telescope").load_extension "file_browser"
vim.keymap.set('n', 'fe', ":Telescope file_browser path=%:p:h<cr>", {noremap = true})
