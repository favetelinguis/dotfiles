---
name: kakoune-script-expert
description: Write, edit, review, and debug Kakoune script for the Kakoune editor. Use when working on `.kak` files, `kakrc`, autoload modules, hooks, commands, options, menus, tmux integrations, or shell-backed Kakoune workflows. Prefer this skill whenever Codex needs to add or change Kakoune scripting while matching existing patterns in `~/.config/kak/autoload` and upstream `share/kak`.
---

# Kakoune Script Expert

## Overview

Use this skill to produce Kakoune script that matches the user's existing Kakoune config and the upstream Kakoune runtime instead of inventing a new style.

## Workflow

1. Read nearby patterns before changing anything.
- If the task touches the user's config, inspect the relevant files in `/home/favetelinguis/.config/kak/autoload/` first.
- Inspect `/home/favetelinguis/.config/kak/kakrc` whenever the change may add, remove, or move keybindings or user-mode maps.
- Read [references/patterns.md](references/patterns.md) and open only the local or upstream files that match the task.

2. Reuse Kakoune primitives before adding shell complexity.
- Prefer `define-command`, `hook`, `map`, `declare-option`, `provide-module`, `require-module`, `menu`, and `complete-command` when they fit.
- Use `evaluate-commands %sh{...}` when shell is the cleanest integration boundary.
- Return Kakoune commands with `printf`; do not emit ad hoc text that Kakoune will misparse.

3. Match the house style already present in this config.
- Use small shell helpers such as `kakquote()` for quoting.
- Keep option declarations explicit, often under `try %{ declare-option ... }` for idempotent startup.
- Use hidden helper commands for internal plumbing and public commands for entry points.
- Do not put keybindings or user-mode maps in autoload modules; define commands in autoload, and place all `map` and `declare-user-mode` statements in `~/.config/kak/kakrc`.
- Group hooks and clean them up with `remove-hooks` or `hook -once -always ...`.
- Use temp shell scripts only when interactive tools like `fzf` or tmux panes make inline quoting harder than a throwaway script.

4. Assume the operating environment the user described.
- Assume Kakoune runs inside tmux.
- Assume `rg`, `fd`, `fzf`, `zoxide`, `lf`, and `chezmoi` are available and may be preferred over slower or clumsier alternatives.
- Favor tmux-aware flows for pickers, REPL-style commands, and external tool handoff.

5. Validate the result.
- If `kak` is available, source the changed file in a noninteractive Kakoune instance to catch syntax errors. Use an explicit quit command so the check terminates: `XDG_RUNTIME_DIR=/tmp kak -n -e 'source /abs/path/to/file.kak; quit!' -ui dummy -q`.
- Do not rely on `kak -n` by itself for validation; it starts Kakoune but does not prove the file sourced successfully.
- In Codex sandboxes, Kakoune may fail to bind its listen socket with `Operation not permitted`; if that happens, rerun the headless source pass with escalated permissions instead of assuming the script is broken.
- If runtime behavior is unclear, inspect the matching upstream runtime file or doc page before changing semantics.

## Implementation Rules

- Prefer extending an existing local module over creating a new parallel command family.
- Follow the naming and grouping patterns already used in `/home/favetelinguis/.config/kak/autoload/`.
- Treat `kakrc` as the only place for keybinding policy. If a feature needs bindings, wire them in `kakrc` rather than inside the autoload file.
- Keep shell blocks POSIX-sh compatible unless the surrounding code clearly relies on something stronger.
- Keep failure messages concrete and return them via `fail`.
- Preserve interactive behavior around selections, clients, panes, and buffers; Kakoune is selection-driven and client-server aware.
- Avoid replacing upstream behavior unless the task explicitly calls for overriding it.

## Validation

- For syntax checks, prefer a headless source pass that actually sources the file and exits cleanly: `XDG_RUNTIME_DIR=/tmp kak -n -e 'source /abs/path/to/file.kak; quit!' -ui dummy -q`.
- If the headless check hangs, verify that you included `quit!`; `-q` alone is not an exit command.
- If the check fails with a listen-socket permission error under Codex, rerun it with escalation before treating it as a Kakoune syntax failure.
- For behavior checks, test the command inside the user's tmux-backed Kakoune workflow when practical.
- For tmux/fzf integrations, treat the headless source pass as syntax-only validation; still do a live tmux smoke test when behavior depends on panes, `kak -p`, or external pickers.
- When adding or changing quoting, menus, hooks, or shell completions, compare against the closest upstream implementation before finalizing.

## References

- Local and upstream lookup map: [references/patterns.md](references/patterns.md)
