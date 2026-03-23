---
name: fzf-scripting-expert
description: Create, review, and refactor fzf scripting for Kakoune and POSIX shell. Use when working on tmux-backed pickers, fzf bindings, preview/reload flows, shell helpers, or Kakoune commands that launch fzf and send results back through kak -p.
---

# fzf Scripting Expert

## Overview

Use this skill to extend or review `fzf` integrations in the style already used in this repo instead of inventing a fresh picker architecture.

Read [references/local-patterns.md](references/local-patterns.md) first. Read [references/upstream-fzf.md](references/upstream-fzf.md) when you need stronger `fzf` mechanics such as preview windows, `reload`, `become`, or richer key bindings.

## Workflow

1. Inspect local truth before changing anything.
- Read the closest local Kakoune or shell implementation first.
- Start with `~/.config/kak/autoload/fzf.kak` and `~/.local/bin/kak-fzf-split-open` for generic picker patterns.
- Also inspect nearby modules such as `notes.kak`, `task.kak`, `git.kak`, and `chezmoi.kak` when the new picker is domain-specific.

2. Preserve the repo's existing architecture.
- For Kakoune-driven pickers, prefer `evaluate-commands %sh{...}` that writes a short temp script and launches it in a tmux split.
- Send the result back to Kakoune with `kak -p "$session"` rather than trying to keep complex editor state inside the picker process.
- Keep reusable shell logic in `~/.local/bin` helpers when a binding or preview command would otherwise become hard to quote.

3. Match the house style.
- Keep shell code POSIX `sh` unless the surrounding file already depends on Bash or Zsh.
- Use small quoting helpers such as `kakquote()` instead of ad hoc escaping.
- Prefer absolute helper paths like `~/.local/bin/kak-fzf-split-open` and `~/.local/bin/kak-task-list` over implicit `PATH` lookup when following local patterns.
- Keep temp scripts self-contained and self-cleaning.

4. Pull in upstream `fzf` patterns selectively.
- Use `--disabled` plus `change:reload` for live search sources such as `rg`.
- Use `execute-silent(...)` when the action should happen without replacing the picker.
- Use `become(...)` when the picker should hand off to a new program or mode cleanly.
- Keep `--preview` scoped to file- or object-like inputs; do not add generic preview defaults everywhere.

5. Validate the result.
- Run `sh -n` on edited shell helpers or generated helper patterns when practical.
- If you changed a `.kak` file, run a headless source pass:
  `XDG_RUNTIME_DIR=/tmp kak -n -e 'source /abs/path/file.kak; quit!' -ui dummy -q`
- Treat tmux- and `fzf`-dependent behavior as needing a live smoke test when feasible.

## Rules

- Prefer extending an existing local picker or helper over creating a parallel command family.
- Keep `fzf` options close to the use case; do not centralize them prematurely unless the surrounding code already does.
- Prefer plain-string delimiters over regex delimiters when possible.
- Use `fd` and `rg` as the first choice for candidate generation in this repo.
- Keep Kakoune keybinding policy in `kakrc`; autoload modules should define commands, not global bindings.
- When adding bindings, headers, or previews, make the accept path and alternate actions obvious from the `fzf` header text.
- For Git-oriented pickers, study `fzf-git.sh` patterns before designing a new action or preview flow.

## Validation

- Syntax-check shell code with `sh -n`.
- Syntax-check Kakoune modules with a headless source pass that actually sources the file and exits.
- When changing quoting, `reload`, `execute`, or `become` behavior, compare the final design against the closest local picker and the relevant upstream `fzf` reference.

## References

- Local patterns: [references/local-patterns.md](references/local-patterns.md)
- Upstream `fzf` patterns: [references/upstream-fzf.md](references/upstream-fzf.md)
