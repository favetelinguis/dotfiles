# chezmoi Workflow

Use this reference when handling dotfiles in this repo.

## Repo patterns

- This repo is intentionally opt-in. Machine-local booleans in `~/.config/chezmoi/chezmoi.toml` decide which targets are active.
- `.chezmoiignore` is the main gating layer. It enables or disables groups of managed files from local `data.apps`, `data.agent`, and `data.shell` values.
- Shared agent skills are stored once in `~/.config/agents/skills` and sourced from this repo under `dot_config/agents/skills`.
- Codex, Claude, and Opencode use compatibility symlinks managed by chezmoi templates, not duplicate copies of each skill.
- There are no repo-tracked chezmoi hook scripts at the moment. The current skill setup mechanism is canonical shared skill content plus agent-specific symlink templates.

## Source-state mapping

- `~/.config/foo/...` -> `dot_config/foo/...`
- `~/.tmux.conf` -> `dot_tmux.conf`
- `~/.emacs.d/...` -> `private_dot_emacs.d/...`
- `~/.local/bin/...` -> `dot_local/bin/...`
- Shared skills -> `dot_config/agents/skills/<skill-name>/...`
- Codex skill compatibility symlink -> `dot_codex/skills/symlink_<skill-name>.tmpl`
- Claude skill compatibility symlink -> `dot_claude/skills/symlink_<skill-name>.tmpl`
- Opencode skill compatibility symlink -> `dot_config/opencode/skills/symlink_<skill-name>.tmpl`

## Preferred command workflow

Inspect:

```sh
chezmoi source-path <target>
chezmoi target-path <source>
chezmoi managed --include files --path-style absolute
chezmoi diff [<target>]
```

Add or remove managed state:

```sh
chezmoi add <target>
chezmoi forget --force --no-tty <target>
```

Sync targets after source edits:

```sh
chezmoi apply --no-tty <target>
```

Use full-state apply only when the task clearly needs it:

```sh
chezmoi apply
```

## Policy for edits

- Read first, then ask before mutating chezmoi source files.
- Never edit live targets in `$HOME` directly when they are managed by chezmoi.
- If the user asks to change a file under `~/.config`, `~/.tmux.conf`, `~/.emacs.d`, or `~/.local`, resolve whether it is managed before editing.
- If the user wants a local-only change that should not be committed to source state, say that explicitly and ask for confirmation because it will drift from chezmoi.
- After mutating source files, apply the touched targets so the user can test immediately.

## Repo-specific notes

- `README.org` documents the opt-in local-config model and the shared-skill layout.
- `.chezmoiignore` already handles whether `.config/agents`, `.codex`, `.claude`, and `.config/opencode` are active based on `data.agent`.
- Kakoune already follows an auto-apply pattern for managed source buffers in `dot_config/kak/autoload/chezmoi.kak`, so syncing after edits matches an existing local workflow.
