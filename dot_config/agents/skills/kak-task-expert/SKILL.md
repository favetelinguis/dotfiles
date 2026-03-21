---
name: kak-task-expert
description: Create and update Kakoune shell-task scripts and their Kakoune integration for the user's `task.kak` workflow. Use when working on `~/.config/kak/autoload/task.kak`, `~/.config/kak/kakrc`, `~/.local/bin/kak-task-list`, `~/.local/bin/kak-task-run`, or individual `~/.local/bin/kak-task-*` scripts that must follow the user's naming, metadata, repo-scoping, tmux/fzf, and sudo conventions.
---

# Kak Task Expert

## Overview

Use this skill to work on the user's Kak task system: executable shell scripts in `~/.local/bin` plus Kakoune commands in `task.kak`.

Read the implementation reference first: [references/implementation.md](references/implementation.md).

## Workflow

1. Inspect the live implementation before changing anything.
- Read `~/.config/kak/autoload/task.kak`.
- Read `~/.local/bin/kak-task-list`.
- Read `~/.local/bin/kak-task-run`.
- Read `~/.config/kak/kakrc` if bindings or user modes are involved.

2. Preserve the current architecture.
- Tasks are executable shell scripts in `~/.local/bin`.
- Project-local tasks do not live in repo directories; project scope is inferred only from the script basename.
- `task.kak` defines commands and plumbing.
- `kakrc` owns `declare-user-mode` and `map` statements.

3. Follow the naming and metadata contract exactly.
- Global tasks: `kak-task--<task-name>`.
- Project tasks: `kak-task-<repo-slug>--<task-name>`.
- Metadata lives in the first 40 lines as shell comments.
- Use only the supported metadata keys documented in the reference.

4. Keep helper resolution explicit.
- `task.kak` and `kak-task-run` call `~/.local/bin/kak-task-list` and `~/.local/bin/kak-task-run` by absolute path.
- Do not switch back to `PATH`-based lookup unless the user explicitly asks for that behavior.

5. Match the current UI behavior.
- Prefer tmux + `fzf` picker when available.
- Keep the Kakoune `menu` fallback.
- Keep fifo output buffers `filetype=make` so existing error navigation still works.

## Rules

- Write task scripts as POSIX `sh` unless the script explicitly needs another shell via shebang.
- Keep task discovery based on filename plus metadata comments, not manifests or sidecar config.
- Keep repo matching based on the active git root basename slug.
- Keep project tasks preferred over same-name global tasks.
- Keep `kak-task-sudo: yes` terminal-only; do not prompt for sudo inside fifo mode.
- Keep autoload modules free of keybindings and user-mode declarations; wire bindings in `kakrc`.

## Validation

- Run `sh -n` on edited helper scripts and task scripts when practical.
- If you change `task.kak`, run a headless source pass when possible:
  `XDG_RUNTIME_DIR=/tmp kak -n -e 'source /abs/path/task.kak; quit!' -ui dummy -q`
- If the sandbox blocks Kakoune listen sockets, rerun the syntax check with escalation instead of assuming the file is broken.
- Smoke-test discovery with representative global and project task names when changing filename parsing or metadata handling.

## References

- Implementation contract: [references/implementation.md](references/implementation.md)
