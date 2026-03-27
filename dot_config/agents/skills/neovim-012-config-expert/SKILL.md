---
name: neovim-012-config-expert
description: Write, edit, review, and debug Neovim Lua, user configuration, and plugin code with a Neovim 0.12-native bias. Use when tasks touch `init.lua`, `lua/**`, `after/**`, `plugin/**`, `ftplugin/**`, `lsp/*.lua`, Neovim plugin repositories, or any Lua written specifically for Neovim. Use alongside `chezmoi-dotfile-expert` whenever the task changes Neovim config under `$HOME`, especially `~/.config/nvim/**`, so edits happen in chezmoi source state and managed targets are applied after changes.
---

# Neovim 0.12 Config Expert

## Overview

Use this skill for Neovim-specific Lua and config work. Prefer Neovim 0.12 built-ins and upstream runtime patterns before reaching for third-party managers, wrappers, or compatibility shims.

## Workflow

1. Resolve the source of truth first.
- If the task touches `~/.config/nvim/**` or another home config path, invoke `chezmoi-dotfile-expert`, inspect the chezmoi source path first, edit source state only, and apply the touched targets after changes.
- If the task touches a Neovim plugin repo, inspect nearby modules, docs, and tests before adding new structure.

2. Prefer native 0.12 features.
- For LSP, use `vim.lsp.config()` and `vim.lsp.enable()`. Prefer `lsp/<name>.lua` or direct config tables over legacy `require('lspconfig').<server>.setup`.
- For package management, prefer `vim.pack.add()`, `vim.pack.update()`, `vim.pack.get()`, and `vim.pack.del()` instead of adding `lazy.nvim`, `packer.nvim`, `paq`, or `mason.nvim` unless the repo already depends on them or the user explicitly asks.
- Prefer built-in primitives such as `vim.keymap.set`, `vim.api.nvim_create_autocmd`, `vim.api.nvim_create_augroup`, `vim.filetype.add`, `vim.system`, `vim.fs`, `vim.uv`, and `vim.iter`.

3. Match the config structure to the runtime behavior.
- Keep `init.lua` as the composition root and move feature logic into `lua/<namespace>/*.lua`.
- Use `after/ftplugin/*.lua`, `plugin/*.lua`, `ftplugin/*.lua`, `lsp/*.lua`, and focused feature modules instead of a monolithic setup file when that fits the task.
- Keep modules idempotent and avoid globals unless exposing a deliberate public API or user command.

4. Keep Lua idiomatic and minimal.
- Use local functions, explicit option tables, and returned modules.
- Add `desc` to user-facing mappings and prefer buffer-local mappings or autocmds when behavior is filetype- or client-specific.
- Avoid compatibility layers for old Neovim versions unless the repo already supports them.

5. Validate against the runtime you actually have.
- If a Neovim 0.12 build is available, run headless checks that load the changed config or module.
- If local `nvim` is older than 0.12, still syntax-check and reason from upstream docs, but call out that runtime validation is limited by version skew.
- For config changes under `$HOME`, finish with the chezmoi apply step from the companion skill.

## References

- Read [references/neovim-0.12-native.md](references/neovim-0.12-native.md) before making choices about LSP setup, package management, or native-vs-plugin tradeoffs.
