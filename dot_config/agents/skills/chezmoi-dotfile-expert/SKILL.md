---
name: chezmoi-dotfile-expert
description: Manage dotfiles through the user's chezmoi source state instead of editing live files in $HOME. Use when working on common config targets such as `~/.config/**`, `~/.tmux.conf`, `~/.emacs.d/**`, `~/.local/**`, agent skill directories, or when answering chezmoi workflow questions about source paths, target paths, add/forget/diff/apply, machine-local enablement, or skill compatibility symlinks.
---

# chezmoi Dotfile Expert

## Overview

Use this skill for any dotfile or config-management task that should go through chezmoi. Treat the chezmoi source repo as the place to inspect and edit, and treat live files in `$HOME` as targets that must stay in sync for immediate testing.

Read [references/chezmoi-workflow.md](references/chezmoi-workflow.md) before changing anything.

## Workflow

1. Inspect repo truth first.
- Read `README.org` and `.chezmoiignore` when the task depends on enablement, agent skill wiring, or path scope.
- Inspect the relevant source files in the chezmoi repo before proposing edits.
- Use `chezmoi source-path`, `chezmoi target-path`, `chezmoi managed`, and `chezmoi diff` to resolve ambiguity before asking the user.

2. Map target paths back to source state.
- `~/.config/...` maps to `dot_config/...`.
- `~/.tmux.conf` maps to `dot_tmux.conf`.
- `~/.emacs.d/...` maps to `private_dot_emacs.d/...`.
- `~/.local/...` maps to `dot_local/...`.
- Shared skills live in `dot_config/agents/skills/<skill-name>`.
- Agent-specific compatibility paths are symlinks managed by templates under `dot_codex/skills/`, `dot_claude/skills/`, and `dot_config/opencode/skills/`.

3. Ask before changing source state.
- If the task would mutate a chezmoi-managed dotfile, explicitly ask whether the user really wants the change made in chezmoi source.
- Do this even when the user asked to change a live config file in `$HOME`; confirm that the change should be made in source state rather than as a local-only experiment.
- If the task is read-only, inspect without asking.

4. Keep edits in the chezmoi repo.
- Do not edit managed targets in `$HOME` directly.
- Do not create parallel copies outside the repo when a managed source file already exists.
- If a target is unmanaged and the user wants it brought under chezmoi, confirm before using `chezmoi add`.

5. Sync the touched files at the end.
- After source edits, apply the touched managed files so the user can test immediately without a manual sync step.
- Default to targeted apply for the touched targets rather than a full `chezmoi apply`.
- Use full `chezmoi apply` only when the user asks for it or when the task clearly spans multiple managed components that must be reconciled together.

## Rules

- Prefer source-state commands and checks over guessing path transforms by hand.
- Preserve the repo's opt-in model based on local `chezmoi.toml` booleans and `.chezmoiignore`.
- Treat `~/.config/agents/skills` as the canonical shared skill location.
- Treat agent-specific skill directories as compatibility layers implemented by chezmoi-managed symlink templates.
- When asked to create or update a chezmoi-related skill, use `skill-creator` and keep the new skill in the shared chezmoi skills tree unless the user explicitly wants a different location.
- If the task may require additional chezmoi-managed hook or compatibility setup for a skill, prompt the user before adding that setup.
- If the user asks for a local-only workaround instead of a source-state change, state clearly that the result will drift from chezmoi and ask for confirmation before proceeding.

## Validation

- Run `chezmoi diff` on the touched targets or the full source tree as appropriate.
- Confirm the final target paths are updated after the apply step.
- For shared skills, verify the canonical skill files and the agent-specific symlink templates point at the same shared directory.
- If the task changed repo structure or enablement behavior, inspect `.chezmoiignore` and the affected templates before finishing.

## References

- Repo-specific workflow and command guide: [references/chezmoi-workflow.md](references/chezmoi-workflow.md)
