# zen_alabaster Neovim config

This Neovim config is built around a local `zen_alabaster` colorscheme:

- Zenburn UI and surface colors
- Alabaster-style restrained syntax highlighting
- definition-first highlighting via Tree-sitter captures and LSP semantic tokens
- native Neovim 0.12 APIs
- no LSP auto-downloads
- no parser auto-installs while editing

## Layout

- `colors/zen_alabaster.lua`: local colorscheme entrypoint
- `lua/zen_alabaster/`: core options, theme, plugin, and LSP bootstrap
- `lsp/*.lua`: server configs consumed by `vim.lsp.enable()`
- `queries/*/highlights.scm`: declaration-oriented Tree-sitter extensions

## Manual setup

1. Install the managed plugin manually:

   - Start Neovim
   - Run `:PackSync`

2. Install the managed Tree-sitter parser set after `nvim-treesitter` is installed:

   - Run `:TSInstallManaged`
   - Update the same parser set later with `:TSUpdateManaged`

3. Install LSP servers manually and place them on `PATH`:

   - `lua-language-server`
   - `ty`
   - `typescript-language-server`
   - `typescript`
   - `gopls`
   - `rust-analyzer`
   - `jdtls`

## Tree-sitter management

- Neovim provides the runtime, parser loading, and query lookup.
- This config provides the managed parser list and local query extensions in `queries/*/highlights.scm`.
- `nvim-treesitter` provides the parser registry, download URLs, build logic, and `:TSInstall` / `:TSUpdate` commands.
- External grammar source URLs are not built into Neovim and are not duplicated in this config.
- This Neovim build does not ship parser binaries on `runtimepath`, so local ftplugins degrade safely until parsers are installed.

## Verification

- `:checkhealth vim.lsp`
- `:TSInstallInfo`
- `:Inspect` on a definition and on a call site
- `:colorscheme zen_alabaster`

Function and method declarations should be accented. Most keywords, operators,
variables, and call sites should stay close to the base text color.
