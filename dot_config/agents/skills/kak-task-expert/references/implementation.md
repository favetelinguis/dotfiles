# Kak Task Implementation

Use this file when creating or modifying the user's Kak task system.

## Contents

- [Source of truth](#source-of-truth)
- [Task naming](#task-naming)
- [Discovery model](#discovery-model)
- [Supported metadata](#supported-metadata)
- [Helper contract](#helper-contract)
- [Kakoune integration](#kakoune-integration)
- [UI behavior](#ui-behavior)
- [Public Kakoune commands](#public-kakoune-commands)
- [Example tasks](#example-tasks)
- [Change guidance](#change-guidance)

## Source of truth

Live files:
- `~/.config/kak/autoload/task.kak`
- `~/.config/kak/kakrc`
- `~/.local/bin/kak-task-list`
- `~/.local/bin/kak-task-run`

Chezmoi source files:
- `dot_config/kak/autoload/task.kak`
- `dot_config/kak/kakrc`
- `dot_local/bin/executable_kak-task-list`
- `dot_local/bin/executable_kak-task-run`

## Task naming

- Global task scripts:
  - `~/.local/bin/kak-task--<task-name>`
- Project task scripts:
  - `~/.local/bin/kak-task-<repo-slug>--<task-name>`

`repo-slug` is:
- derived from `basename "$git_root"`
- lowercased
- non-alphanumeric runs collapsed to `-`

Example:
- repo root `~/src/My App` -> slug `my-app`
- project task: `kak-task-my-app--test`

## Discovery model

`kak-task-list` scans only `~/.local/bin/kak-task-*`.

Discovery rules:
- include only executable regular files
- global tasks always qualify
- project tasks qualify only when the active context is inside a git repo and the task prefix matches the active repo slug
- if a project task and a global task share the same logical task name, prefer the project task

Context resolution:
- if the input is a directory, use it
- if the input is a file, use its parent directory
- otherwise fall back to `PWD`

## Supported metadata

Read only the first 40 lines of each task script.

Supported comment headers:
- `# kak-task-title: ...`
- `# kak-task-desc: ...`
- `# kak-task-group: ...`
- `# kak-task-sudo: no|yes`
- `# kak-task-cwd: repo|cwd|subdir:<path>`
- `# kak-task-mode: fifo|terminal`
- `# kak-task-error-pattern: <regex>`

Defaults:
- `title`: derived from task name, replacing `-` and `_` with spaces
- `group`: `misc`
- `sudo`: `no`
- `cwd`: `repo` for project tasks, `cwd` for global tasks
- `mode`: `fifo`
- if `sudo=yes`, force `mode=terminal`

## Helper contract

`kak-task-list <context>` emits tab-separated rows:

1. script basename
2. logical task name
3. scope: `global` or `project`
4. title
5. group
6. description
7. mode
8. sudo mode
9. cwd mode
10. error pattern

`kak-task-run <script-basename> [context] [args...]`:
- resolves the matching row via `~/.local/bin/kak-task-list`
- computes repo root and repo slug from the context
- computes working directory from `cwd_mode`
- exports:
  - `KAK_TASK_NAME`
  - `KAK_TASK_SCOPE`
  - `KAK_TASK_REPO_ROOT`
  - `KAK_TASK_REPO_SLUG`
  - `KAK_TASK_FILE`
- `cd`s into the computed workdir
- `exec`s the task script

Helper lookup:
- use explicit helper paths under `~/.local/bin`
- do not rely on `PATH` to find `kak-task-list` or `kak-task-run`

## Kakoune integration

`task.kak` owns:
- task discovery
- picker construction
- fifo output buffers
- terminal launches
- rerun state
- error navigation commands

`kakrc` owns:
- `declare-user-mode task`
- all `map` bindings for task mode
- the global entry key that enters task mode

Do not add hidden keybindings to autoload files.

## UI behavior

Picker behavior:
- if inside tmux and `fzf` exists, open a tmux split picker
- otherwise build a Kakoune `menu -auto-single`

Display behavior:
- show scope/group/title and optionally description

Execution behavior:
- fifo tasks open a `*task* <script-basename>` buffer
- fifo buffers set `filetype=make`
- fifo buffers set `jump_current_line 0`
- if the task has an error pattern, set buffer `make_error_pattern`
- terminal tasks require tmux

Sudo behavior:
- `kak-task-sudo: yes` means terminal mode only
- warm credentials with `sudo -v` if `sudo -n true` fails
- run the task script normally after credentials are ready
- do not auto-prefix arbitrary commands with `sudo`

## Public Kakoune commands

- `task-menu`
- `task-run <script-basename> [context-path]`
- `task-rerun`
- `task-open-last-output`
- `task-next-error`
- `task-previous-error`

## Example tasks

Global task:

```sh
#!/bin/sh
# kak-task-title: Sync dotfiles
# kak-task-desc: Run chezmoi apply from the current shell context
exec chezmoi apply
```

Path:
- `~/.local/bin/kak-task--sync-dotfiles`

Project task:

```sh
#!/bin/sh
# kak-task-title: Test
# kak-task-group: ci
# kak-task-cwd: repo
exec cargo test
```

Path:
- `~/.local/bin/kak-task-myrepo--test`

Sudo task:

```sh
#!/bin/sh
# kak-task-title: Install
# kak-task-sudo: yes
# kak-task-mode: terminal
exec ./scripts/install.sh
```

## Change guidance

When adding a new task:
- choose the basename first
- add metadata only if it improves title, group, description, cwd, mode, or error parsing
- keep the script directly runnable from the shell

When changing task discovery:
- preserve the current basename contract unless the user explicitly asks to migrate it
- preserve project-over-global precedence

When changing Kakoune integration:
- keep command definitions in `task.kak`
- move any binding changes to `kakrc`
