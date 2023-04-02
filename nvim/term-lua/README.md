A NVIM config that is centered around minimal config and reuse terminal tools as much as possible

- Terminal tools - avoid TUI since it do not compose, this means lazygit is out :(
	- ripgrep - use instead of fd to list files just to keep number of commands to lear down
	- fzf - combine with ripgrep to make tons of util functions in .zsh for searcing files, finding symbols in buffers and doing git commands
	  for example se how https://github.com/wfxr/forgit works but implement my work bash functions, are tons of examples on how to add pager etc
	- fzf for tab-completion https://github.com/lincheney/fzf-tab-completion
	- autojump - by far the best way to navigate your daily dev station
	- git-status blazing fast status https://github.com/romkatv/gitstatus
	- pager and differ https://github.com/dandavison/delta
	- replace ls to get tree https://github.com/ogham/exa Think of how tree view could be used to replace nerdtree and similar tools
- Plugin
	- Theme https://github.com/p00f/alabaster.nvim
	- neovim-remote - to use terminal in nvim without nesting nvim instances
		-  https://github.com/mhinz/neovim-remote
		- check editor command here https://www.reddit.com/r/neovim/comments/fm9c4s/opening_files_from_within_neovim_terminal/
	- https://github.com/akinsho/toggleterm.nvim
		- use this to build custom .zsh functions that i can trigger when i toggle a terminal. So for example search file would be fzf in a terminal that execute a custom function i have in .zshrc
	- ALE or null-ls and github copilot
		- for coding dont use lsp since no one understand it and you cant use it in your CI pipe insted use language specific linters and formatters that are also used in CI pipes
	  	  skip any autocompletion and use github copilot.
