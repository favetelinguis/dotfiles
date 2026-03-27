# Neovim 0.12 Native Notes

## Current status

- As of 2026-03-27, the official releases page shows a nightly prerelease build for `v0.12.0-dev` and `v0.11.6` as the latest stable release.
- Treat Neovim 0.12 APIs as the right direction for new config, but remember that prerelease details can still move before a final `0.12.0` tag.

Sources:
- https://github.com/neovim/neovim-releases/releases

## Native-first defaults

- Prefer built-in Neovim APIs over external wrappers when the native path is already good enough.
- Only add third-party plugin managers, LSP installers, or compatibility layers when the repo already uses them or the user explicitly asks for them.
- When extending an existing config, preserve the repo's current architecture unless the task is explicitly a migration.

## LSP

- Use `vim.lsp.config(name, cfg)` to define or extend configs.
- Use `vim.lsp.enable(name)` to activate them based on `filetypes`, `root_markers`, or `root_dir`.
- Prefer `lsp/<name>.lua` on `runtimepath` or explicit Lua config tables for reusable server config.
- Use `vim.filetype.add()` for custom filetype detection before reaching for broader hacks.
- `nvim-lspconfig` is still useful as a source of server-specific config examples, but do not default to the legacy `require('lspconfig').<server>.setup` style in new code.

Sources:
- https://neovim.io/doc/user/lsp.html

## Package management with vim.pack

- `vim.pack` is the native package manager and is still marked experimental, but the docs describe it as stable enough for daily use.
- Use `vim.pack.add()` to register and install plugins.
- Use `vim.pack.update()` to review and apply updates.
- Use `vim.pack.get()` to inspect managed plugins and `vim.pack.del()` to remove them.
- Track `nvim-pack-lock.json` in version control when the config should be reproducible across machines.
- Do not introduce `lazy.nvim`, `packer.nvim`, or similar managers by default if `vim.pack` can cover the need.

Sources:
- https://neovim.io/doc/user/pack/

## Useful built-ins to prefer

- `vim.keymap.set`
- `vim.api.nvim_create_autocmd`
- `vim.api.nvim_create_augroup`
- `vim.api.nvim_create_user_command`
- `vim.system`
- `vim.fs`
- `vim.uv`
- `vim.iter`
- `vim.tbl_deep_extend`
- `vim.schedule`
