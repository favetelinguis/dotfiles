# Nushell Language And Idioms

Distilled from:
- https://www.nushell.sh/lang-guide/

## Mental model

- Treat Nushell as a shell for structured data, not a text stream with convenience helpers.
- Prefer records, lists, and tables over newline-delimited text until the final output boundary.
- Use cell paths such as `foo.bar.0` to access nested data instead of reparsing strings.

## Choose the right building block

- Use a plain pipeline for one-shot exploration and transformation.
- Use `def` for reusable local commands.
- Use `export def` inside a module when other files should import the command.
- Use `let` to name intermediate values and reduce repeated cell paths.
- Use closures like `{ |row| ... }` for row-local transformations and predicates.

## High-value data-shaping habits

- Use `get` to drill into values and cell paths.
- Use `select` to keep only the columns or fields you want to preserve.
- Use `where` to filter rows by predicate and `filter` when a closure-based filter is clearer.
- Use `update` when the field must already exist and `upsert` when it may need to be created.
- Use `insert` for a new column or field and `merge` for record-to-record composition.
- Use `reduce` for aggregation that does not fit a simple built-in.
- Use `each` for per-row transforms and reserve `par-each` for independent work where concurrency is worth the overhead.

## Flow control

- Use `if`, `match`, `for`, `while`, and `loop` when the control flow is clearer than stacking more pipeline stages.
- Use `try`/`catch` around fallible parsing, IO, or external-command boundaries.
- Keep error handling close to the failure site. Prefer small guarded operations over wrapping a long pipeline in one broad `try`.

## Modules and reusable command surfaces

- Keep shared helpers in module files and import them with `use`.
- Export only the commands or aliases intended for external consumption.
- Use `export extern` to describe external CLI signatures, flags, and completion hooks.
- When a module needs to influence environment setup, keep that concern explicit and separate from pure command definitions.

## External commands

- Prefer a Nushell built-in when one already models the data natively.
- If an external command is required, pass arguments deliberately rather than building one shell-escaped string.
- Parse stdout immediately into structured data when the tool supports JSON, TSV, CSV, or another machine-readable format.
- Capture stdout, stderr, and exit status with `complete` when behavior depends on command failure or diagnostics.

## Practical style rules

- Favor short, composable helpers over giant one-liners.
- Introduce a `let` binding when a pipeline becomes hard to read or a cell path repeats.
- Keep pure data transformation separate from side effects such as `save`, filesystem mutation, or network access.
- Prefer explicit command signatures and predictable return shapes over shell-like positional magic.
