# Upstream fzf Patterns

Use these sources to upgrade local pickers without drifting away from the repo's style:

- fzf wiki: <https://github.com/junegunn/fzf/wiki>
- fzf README advanced topics: <https://raw.githubusercontent.com/junegunn/fzf/master/README.md>
- fzf-git.sh repo: <https://github.com/junegunn/fzf-git.sh>
- fzf-git.sh script: <https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh>

## High-Value Patterns

### `execute(...)` and `execute-silent(...)`

Use these when a key should trigger side effects without accepting the current item as the main result. Local example: `kak-fzf-split-open` is a good target for `execute-silent(...)` from a file or grep picker.

Good fit:

- open the current item in another tmux split
- copy a value
- trigger an external helper while leaving the picker active or aborting intentionally

### `become(...)`

Use `become(...)` when the picker should cleanly hand off to a new program or sub-mode instead of returning to the current `fzf` process.

Good fit:

- switching from a branch picker into a commit picker
- handing selected Git refs directly to `git checkout`, `vim`, or another tool
- multi-select flows where command substitution would be fragile

### `reload(...)`

Use `reload(...)` for dynamic sources. The core `fzf` ripgrep example and `fzf-git.sh` both rely on event-driven reloading rather than building a second filtering layer on top of stale input.

Good fit:

- `change:reload:rg ... {q} || true` for live grep
- mode toggles such as "files vs directories" or "current refs vs all refs"
- mutating lists where a key both performs an action and refreshes the candidates

### `--preview`

Use previews only when the input format supports meaningful inspection. `fzf-git.sh` treats previews as a first-class part of Git-object browsing and pairs them with preview-window toggles.

Good fit:

- `bat` or `cat` for file content
- `git show`, `git diff`, or `git log` for Git objects
- explicit preview-window bindings such as `ctrl-/:change-preview-window(...)`

Avoid:

- putting file-only preview defaults into a global `FZF_DEFAULT_OPTS`
- previews for arbitrary text streams where the command cannot interpret the line safely

## Patterns Worth Borrowing From `fzf-git.sh`

- Factor common `fzf` invocation into a helper function, then pass use-case-specific flags and bindings on top.
- Keep preview commands and color decisions behind helper functions instead of repeating long shell fragments everywhere.
- Use headers and border labels to teach the picker's alternate actions.
- Use `alt-*` or `ctrl-*` bindings to switch modes by combining `change-*`, `reload(...)`, and `become(...)`.
- When parsing structured lines, keep extraction close to the binding so the selected fields are obvious.

## Guardrails

- Prefer local temp-script and `kak -p` flows for Kakoune integration even when upstream shell-only examples use direct `become(vim ...)`.
- Prefer plain delimiters and simple field extraction before reaching for heavier parsing.
- Preserve explicit tmux assumptions in this repo; do not silently replace tmux-backed flows with generic inline `fzf --tmux` usage unless the task calls for it.
