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

Supported task scripts:
- `~/.local/bin/kak-task--<task-name>`

Chezmoi source path:
- `dot_local/bin/executable_kak-task--<task-name>`

Logical task names are derived from the basename suffix after `kak-task--`.

## Discovery model

`kak-task-list` scans only `~/.local/bin/kak-task--*`.

Discovery rules:
- include only executable regular files
- do not scan repo-scoped or slug-prefixed basenames
- sort by group, title, then task name

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
- `# kak-task-cwd: repo|cwd|subdir:<path>|<absolute-path>`
- `# kak-task-mode: fifo|terminal`
- `# kak-task-error-pattern: <regex>`

Defaults:
- `title`: derived from task name, replacing `-` and `_` with spaces
- `group`: `misc`
- `sudo`: `no`
- `cwd`: `cwd`
- `mode`: `fifo`
- if `sudo=yes`, force `mode=terminal`

`cwd` handling:
- `repo`: use the active git root; fail if no repo is active
- `cwd`: use the resolved context directory
- `subdir:<path>`: use `<repo-root>/<path>` when inside a repo, otherwise `<context-dir>/<path>`
- `/absolute/path`: use the path as-is

## Helper contract

`kak-task-list <context>` emits tab-separated rows:

1. script basename
2. logical task name
3. title
4. group
5. description
6. mode
7. sudo mode
8. cwd mode
9. error pattern

`kak-task-run <script-basename> [context] [args...]`:
- resolves the matching row via `~/.local/bin/kak-task-list`
- computes repo root and repo slug from the context
- computes working directory from `cwd_mode`
- exports:
  - `KAK_TASK_NAME`
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
- pid/log tracking for fifo tasks
- error navigation commands
- task cancellation and running-task lookup

`kakrc` owns:
- `declare-user-mode task`
- all `map` bindings for task mode
- the global entry key that enters task mode

Do not add hidden keybindings to autoload files.

## UI behavior

Picker behavior:
- if inside tmux and `fzf` exists, open a tmux split picker
- otherwise build a Kakoune `menu`

Display behavior:
- show `[group] title` and append the description when present

Execution behavior:
- fifo tasks open a buffer named `*task:<script-basename>:<context-name>*`
- fifo tasks write output to `${TMPDIR:-/tmp}/kak-task-pids/<basename>@<context>.log`
- fifo tasks track the background pid in `${TMPDIR:-/tmp}/kak-task-pids/<basename>@<context>`
- fifo tasks store metadata in a sibling `.meta` file for `task-find`
- prevent starting the same task twice in the same context while its pid is still alive
- fifo buffers set `filetype=make`
- fifo buffers set `jump_current_line 0`
- if the task has an error pattern, set buffer `make_error_pattern`
- terminal tasks require tmux

`task-find` behavior:
- requires tmux and `fzf`
- lists active fifo tasks from pid/meta files
- reopens or recreates the fifo tail buffer for the chosen running task

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
- `task-cancel`
- `task-find`

Task mode bindings in `kakrc`:
- `t` opens the task picker
- `r` reruns the last task
- `o` opens the last output buffer
- `n` and `p` navigate task errors
- `x` cancels the last running fifo task
- `f` finds running fifo tasks

## Example tasks

Current-directory task:

```sh
#!/bin/sh
# kak-task-title: Sync dotfiles
# kak-task-desc: Run chezmoi apply from the current shell context
exec chezmoi apply
```

Path:
- `~/.local/bin/kak-task--sync-dotfiles`

Repo-root task:

```sh
#!/bin/sh
# kak-task-title: Test
# kak-task-group: ci
# kak-task-cwd: repo
exec cargo test
```

Path:
- `~/.local/bin/kak-task--test`

Absolute-path task:

```sh
#!/bin/sh
# kak-task-title: Deploy
# kak-task-cwd: /srv/myapp
exec ./deploy.sh
```

Path:
- `~/.local/bin/kak-task--deploy`

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
- preserve the `kak-task--<task-name>` basename contract unless the user explicitly asks to migrate it
- keep discovery limited to executable regular files under `~/.local/bin`

When changing Kakoune integration:
- keep command definitions in `task.kak`
- move any binding changes to `kakrc`
