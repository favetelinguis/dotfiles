# Local fzf Patterns

Read these files first when the task is about local `fzf` behavior:

- `/home/favetelinguis/.config/kak/autoload/fzf.kak`
  - Base pattern for tmux-backed Kakoune pickers.
  - Uses `evaluate-commands %sh{...}` to capture session/client state, writes a temp shell script with `mktemp`, then opens it via `tmux-terminal-vertical`.
  - Sends the final action back through `kak -p "$session"`.
- `/home/favetelinguis/.local/bin/kak-fzf-split-open`
  - Canonical shell helper for alternate `ctrl-o` behavior.
  - Accepts picker output, parses either `path` or `path:line:content`, chooses split direction from tmux layout, and opens the result in the original Kakoune session.
- `/home/favetelinguis/.config/kak/autoload/notes.kak`
  - Reuses the temp-script pattern for note listing and ripgrep-driven note search.
- `/home/favetelinguis/.config/kak/autoload/task.kak`
  - Shows the repo style for richer list shaping before piping into `fzf`, including `awk` formatting, tab delimiters, and tmux fallback behavior.
- `/home/favetelinguis/.config/kak/autoload/git.kak`
  - Shows a larger tmux/fzf workflow with helper functions, explicit dependency checks, and more structured command handoff back into Kakoune.
- `/home/favetelinguis/.config/kak/autoload/chezmoi.kak`
  - Small, direct picker that turns `chezmoi managed` output back into source-state edits.

## Patterns To Reuse

- Capture `session`, `client`, and any tmux pane metadata before launching `fzf`.
- Prefer a temp script when nested quoting would otherwise become brittle.
- Escape Kakoune-facing strings with single-quote doubling: `sed "s/'/''/g"`.
- Keep picker scripts self-cleaning with `rm -f "$tmp"` on both success and cancel.
- Use `fd` as the fast default source for file pickers; fall back to `find` only when necessary.
- Use `rg --line-number --no-heading --with-filename --smart-case` for grep-style pickers.
- Expose alternate actions in the `fzf` header, especially when using `ctrl-o`, `alt-*`, or `ctrl-*` bindings.

## Local Architecture Rules

- Kakoune autoload modules own commands and shell glue.
- `kakrc` owns user modes and keymaps.
- Reusable shell helpers live in `~/.local/bin` as standalone executables when the action is large enough to deserve its own file.
- Absolute helper paths are preferred in this repo for predictable behavior.
