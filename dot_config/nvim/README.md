# zen_alabaster Neovim config

This Neovim config is built around a local `zen_alabaster` colorscheme:

- Zenburn UI and surface colors
- Alabaster-style restrained syntax highlighting
- definition-first highlighting via Tree-sitter captures and LSP semantic tokens
- native Neovim 0.12 APIs
- no LSP auto-downloads
- no parser auto-installs

## Layout

- `colors/zen_alabaster.lua`: local colorscheme entrypoint
- `lua/zen_alabaster/`: core options, theme, plugin, and LSP bootstrap
- `lsp/*.lua`: server configs consumed by `vim.lsp.enable()`
- `queries/*/highlights.scm`: declaration-oriented Tree-sitter extensions

## Manual setup

1. Install the managed plugin manually:

   - Start Neovim
   - Run `:PackSync`

2. Install Tree-sitter parsers manually after `nvim-treesitter` is installed:

   - `:TSInstall lua vim vimdoc query java javascript typescript tsx python go rust`

3. Install LSP servers manually and place them on `PATH`:

   - `lua-language-server`
   - `ty`
   - `typescript-language-server`
   - `typescript`
   - `gopls`
   - `rust-analyzer`
   - `jdtls`

## Verification

- `:checkhealth vim.lsp`
- `:Inspect` on a definition and on a call site
- `:colorscheme zen_alabaster`

Function and method declarations should be accented. Most keywords, operators,
variables, and call sites should stay close to the base text color.
