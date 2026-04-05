---
name: nushell-script-expert
description: Write, review, refactor, and debug Nushell code with a structured-data-first bias. Use when tasks touch `.nu` files, `config.nu`, `env.nu`, Nushell modules, custom commands, `extern` definitions, completers, or shell pipelines being translated into idiomatic Nushell. Use alongside `chezmoi-dotfile-expert` whenever Nushell config under `$HOME` is managed in chezmoi.
---

# Nushell Script Expert

## Overview

Use this skill for Nushell-specific scripting and configuration work. Prefer Nushell's typed pipelines, records, lists, cell paths, and built-in format/command support before falling back to line-oriented text processing or shell-compatible habits.

## Workflow

1. Resolve the source of truth first.
- If the task touches a home-directory config path such as `~/.config/nushell/**`, invoke `chezmoi-dotfile-expert`, edit the chezmoi source state, and apply the touched target files afterward.
- If the task is in a repo, inspect existing `.nu` files, modules, and naming patterns before introducing new structure.

2. Model the data before writing the pipeline.
- Prefer `open`, `from json`, `from yaml`, `from toml`, `from csv`, and similar parsers over manual `lines`/`split` logic when the input format is known.
- Think in records, lists, and tables. Reach for `get`, `select`, `where`, `update`, `upsert`, `insert`, `merge`, `sort-by`, `group-by`, `reduce`, `transpose`, and `enumerate` before string munging.
- Use cell paths and closures to keep transformations local and explicit.

3. Choose the right Nushell construct.
- Use ad-hoc pipelines for one-off data shaping.
- Use `def` for reusable commands inside one file and `export def` inside modules for public commands.
- Use modules plus `use` when the task involves shared helpers, completions, or a reusable command surface.
- Use `export extern` for external CLI signatures and completions when wrapping non-Nu tools.

4. Keep external-command boundaries explicit.
- Prefer built-ins when Nushell already has a native command family for the job.
- When calling external commands, pass arguments deliberately, capture results with `complete` when exit status matters, and parse stdout into structured data immediately.
- Avoid shell-escaped string concatenation when lists, records, or interpolation would be clearer.

5. Validate in Nushell when possible.
- If `nu` is installed, use `nu -c` for syntax and behavior checks on small examples or changed files.
- Use `help <command>`, `help commands`, and `scope commands` to verify uncertain command names or signatures instead of guessing.
- If the task changes a config or module, sanity-check imports, `NU_LIB_DIRS` usage, and any completion hooks.

## Guidelines

- Favor pipelines that preserve structure for as long as possible. Convert to text only at output boundaries.
- Prefer small closures such as `{ |row| ... }` and named helpers over deeply nested one-liners.
- Use `let` for intermediate values when it clarifies types or repeated cell paths.
- Keep side effects narrow. Separate pure data transformation from `save`, file mutation, network calls, or external commands.
- Be cautious when round-tripping structured files through `open | ... | save`; serializers may reorder keys or normalize formatting.
- Prefer modules and exported commands over copying the same logic across multiple `.nu` files.

## References

- Read [references/language-and-idioms.md](references/language-and-idioms.md) before designing command signatures, closures, modules, or control flow.
- Read [references/cookbook-patterns.md](references/cookbook-patterns.md) for practical patterns around help, parsing, file editing, custom completers, and module/completion layout.
- Read [references/command-families.md](references/command-families.md) when choosing built-ins for shaping data, handling paths, parsing formats, or inspecting the runtime.
