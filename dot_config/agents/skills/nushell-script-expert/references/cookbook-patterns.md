# Nushell Cookbook Patterns

Distilled from:
- https://www.nushell.sh/cookbook/

## Help and discovery

- Start with `help commands` to search the built-in surface area from inside Nushell.
- Use `help <command>` before guessing flags, input shapes, or examples.
- Reach for `scope commands`, `scope aliases`, `scope modules`, and related `scope` views when debugging what is actually loaded.

## Parsing and reshaping text

- Prefer built-in parsers for standard formats first.
- For line-oriented custom formats, a common pattern is `open ... | lines | split column ... | skip 1 | sort-by ...`.
- Use `parse`, `split row`, `split column`, `detect columns`, and string helpers when the source is semi-structured rather than fully machine-readable.

## Editing structured files

- The core pattern is `open file | <transform> | save -f file`.
- `upsert` is useful for targeted edits inside structured formats like TOML, YAML, or JSON.
- Expect serializers to normalize or reorder content. If byte-for-byte formatting matters, operate on raw text instead of round-tripping structured data.

## Modules, custom completers, and external completers

- Keep reusable completion logic in modules and import it explicitly.
- Use `export extern` to document an external command surface and attach typed arguments or completion sources.
- Put completion modules on `NU_LIB_DIRS` so they can be imported cleanly from `config.nu`.
- External completers often return plain text; normalize them into tables early so later logic can stay structured.

## Configuration conventions

- Treat `config.nu` as the place for interactive shell behavior and imports.
- Treat `env.nu` as the place for environment-variable setup such as `NU_LIB_DIRS`.
- Keep reusable helpers in separate module files instead of burying large definitions inline in `config.nu`.

## File and path workflows

- Use `open` for supported formats and `ls`, `glob`, `path join`, `path expand`, and related path commands for filesystem-safe composition.
- When a command may emit paths with spaces or special characters, preserve them as structured values rather than flattening them into shell text too early.

## Good default moves

- When wrapping another CLI, see whether it can emit JSON and parse that immediately.
- When building completions, produce values plus descriptions in a tabular shape.
- When converting a shell snippet to Nushell, replace ad-hoc text splitting with typed parsing and cell-path access wherever possible.
