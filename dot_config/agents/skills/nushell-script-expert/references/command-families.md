# Nushell Command Families

Distilled from:
- https://www.nushell.sh/commands/

## Discovery and inspection

- `help commands`: list commands from inside Nushell.
- `help <command>`: inspect signatures, examples, and flags.
- `scope ...`: inspect loaded commands, aliases, variables, modules, and more.
- `describe`: inspect the shape and type of pipeline values.

## Data access and filtering

- `get`, `select`, `reject`
- `where`, `filter`, `find`, `any`, `all`
- `first`, `last`, `skip`, `take`, `slice`

## Table and record transforms

- `update`, `upsert`, `insert`, `rename`, `move`, `merge`
- `sort-by`, `group-by`, `uniq`, `transpose`, `flatten`
- `enumerate`, `reduce`, `each`, `par-each`

## Strings and parsing

- `parse`, `split row`, `split column`, `lines`
- `str trim`, `str replace`, `str join`, `str contains`
- `from json`, `from yaml`, `from toml`, `from csv`, `from tsv`
- `to json`, `to yaml`, `to toml`, `to csv`, `to tsv`

## Filesystem and paths

- `open`, `save`, `ls`, `glob`, `cp`, `mv`, `rm`, `mkdir`
- `path join`, `path expand`, `path dirname`, `path basename`, `path exists`

## Control flow and safety

- `if`, `match`, `for`, `while`, `loop`
- `try`, `catch`, `error make`
- `do`, `complete`

## Modules and command surfaces

- `def`, `export def`, `alias`
- `module`, `use`, `source-env`
- `extern`, `export extern`

## Search strategy

- Start with `help commands | where name =~ 'json|path|http|str|date'` to narrow the surface area.
- Prefer built-ins in the matching family before reaching for external tools.
- If multiple commands look close, inspect examples with `help <command>` and pick the one that preserves the richest structure.
