---
name: kak-task-expert
description: Create and update Kakoune shell-task scripts and their Kakoune integration for the user's `task.kak` workflow. Use when working on `~/.config/kak/autoload/task.kak`, `~/.config/kak/kakrc`, `~/.local/bin/kak-task-list`, `~/.local/bin/kak-task-run`, or individual `~/.local/bin/kak-task--*` scripts that must follow the user's naming, metadata, tmux/fzf, fifo, and sudo conventions.
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
- Supported task basenames are global-only: `kak-task--<task-name>`.
- `task.kak` defines commands and plumbing.
- `kakrc` owns `declare-user-mode` and `map` statements.

3. Follow the naming and metadata contract exactly.
- Task scripts use the basename form `kak-task--<task-name>`.
- Metadata lives in the first 40 lines as shell comments.
- Use only the supported metadata keys documented in the reference.
- In chezmoi source, create task scripts as `dot_local/bin/executable_kak-task--<task-name>`.

4. Keep helper resolution explicit.
- `task.kak` and `kak-task-run` call `~/.local/bin/kak-task-list` and `~/.local/bin/kak-task-run` by absolute path.
- Do not switch back to `PATH`-based lookup unless the user explicitly asks for that behavior.

5. Match the current UI and execution behavior.
- Prefer tmux + `fzf` picker when available.
- Keep the Kakoune `menu` fallback.
- Keep fifo output buffers `filetype=make` so existing error navigation still works.
- Preserve fifo pid/log tracking and the `task-cancel` / `task-find` workflow.

## Rules

- Write task scripts as POSIX `sh` unless the script explicitly needs another shell via shebang.
- Keep task discovery based on filename plus metadata comments, not manifests or sidecar config.
- Keep discovery limited to executable `kak-task--*` scripts.
- Keep `kak-task-sudo: yes` terminal-only; do not prompt for sudo inside fifo mode.
- Keep `kak-task-cwd` limited to `repo`, `cwd`, `subdir:<path>`, or an absolute path.
- Remember the exported environment only includes `KAK_TASK_NAME`, `KAK_TASK_REPO_ROOT`, `KAK_TASK_REPO_SLUG`, and `KAK_TASK_FILE`.
- Keep autoload modules free of keybindings and user-mode declarations; wire bindings in `kakrc`.

## Validation

- Run `sh -n` on edited helper scripts and task scripts when practical.
- If you change `task.kak`, run a headless source pass when possible:
  `XDG_RUNTIME_DIR=/tmp kak -n -e 'source /abs/path/task.kak; quit!' -ui dummy -q`
- If the sandbox blocks Kakoune listen sockets, rerun the syntax check with escalation instead of assuming the file is broken.
- Smoke-test discovery with representative `kak-task--*` names when changing filename parsing or metadata handling.
- Smoke-test `kak-task-run` for `cwd`, `repo`, `subdir:`, and absolute-path task scripts when touching cwd or environment behavior.

## References

- Implementation contract: [references/implementation.md](references/implementation.md)
