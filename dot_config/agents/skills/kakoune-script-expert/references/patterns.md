# Kakoune Scripting Patterns

Use this file as a lookup map. Open only the files that match the current task.

## Local config patterns

- `/home/favetelinguis/.config/kak/autoload/agent.kak`
  - tmux pane discovery, menu construction, `kakquote`, bracketed paste, hidden state options.
- `/home/favetelinguis/.config/kak/autoload/fzf.kak`
  - fzf pickers launched in tmux splits, temp shell script pattern, `fd`/`rg` integration.
- `/home/favetelinguis/.config/kak/autoload/chezmoi.kak`
  - buffer state sync, command wrappers around `chezmoi`, hook lifecycle, error propagation.
- `/home/favetelinguis/.config/kak/autoload/notes.kak`
  - hidden helper commands, prompt-driven file creation, repo-aware workflows, repeated shell helper style.
- `/home/favetelinguis/.config/kak/autoload/git.kak`
  - user mode bindings and concise command-family exposure.
- `/home/favetelinguis/.config/kak/autoload/lsp.kak`
  - inspect when the task overlaps LSP integration or buffer-local server setup.

## Upstream Kakoune runtime files

These live under Kakoune's runtime `share/kak/` in an installed build, or in the upstream repo at `https://github.com/mawww/kakoune`.

- `share/kak/autoload/windowing/repl/tmux.kak`
  - canonical tmux REPL pane integration and tmux option handling.
- `share/kak/autoload/tools/menu.kak`
  - canonical menu construction, shell quoting, and prompt-backed selection flow.
- `share/kak/autoload/tools/git.kak`
  - large real-world command wrapper with completions, fifo usage, hidden options, and helper functions.
- `share/kak/autoload/filetype/kakrc.kak`
  - Kakoune's own filetype setup, highlighters, indentation hooks, and module structure for Kak script.
- `share/kak/rc/filetype/*.kak`
  - filetype hook and module patterns worth copying for language-specific behavior.
- `share/kak/autoload/tools/*.kak`
  - built-in command patterns for menus, grep, patching, formatting, and windowing.

## Upstream docs worth reading when semantics matter

- `doc/pages/execeval.asciidoc`
  - `execute-keys` and `evaluate-commands`.
- `doc/pages/expansions.asciidoc`
  - `%val`, `%opt`, `%arg`, quoting, and expansion timing.
- `doc/pages/command-parsing.asciidoc`
  - command boundaries, quoting rules, and parser behavior.
- `doc/pages/hooks.asciidoc`
  - hook groups, hook scope, and cleanup expectations.
- `doc/pages/options.asciidoc`
  - option types, scopes, and declaration rules.

## Pattern selection guide

- For tmux panes, REPLs, or external program handoff: start with local `agent.kak` and `fzf.kak`, then compare `share/kak/autoload/windowing/repl/tmux.kak`.
- For pickers, menus, or prompt-driven choices: compare local menu construction with `share/kak/autoload/tools/menu.kak`.
- For shell-backed command families: compare local `chezmoi.kak` or `notes.kak` with `share/kak/autoload/tools/git.kak`.
- For filetype-specific logic or Kak script editing support: inspect `share/kak/autoload/filetype/kakrc.kak` and nearby `share/kak/rc/filetype/*.kak`.
- For quoting or expansion bugs: read `doc/pages/expansions.asciidoc` and `doc/pages/command-parsing.asciidoc` before patching.
