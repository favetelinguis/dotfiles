# WezTerm Notes

Use this file when the task depends on how WezTerm discovers config files, loads helper modules, reloads configuration, or wires callbacks and startup behavior.

## Config Discovery

- WezTerm resolves config in this order: `--config-file`, `$WEZTERM_CONFIG_FILE`, `$XDG_CONFIG_HOME/wezterm/wezterm.lua`, `$HOME/.config/wezterm/wezterm.lua`, then `$HOME/.wezterm.lua`.
- The docs recommend starting with `$HOME/.wezterm.lua`, while multi-file configs can live in `$HOME/.config/wezterm/wezterm.lua`.
- The loaded config file is watched for changes and most options reload automatically. `CTRL+SHIFT+R` also forces a reload.
- The config may be evaluated multiple times per process at startup and reload, so avoid top-level side effects.

## Modules and Paths

- WezTerm config uses Lua 5.4.
- `package.path` is configured to search `~/.config/wezterm` and `~/.wezterm` before system Lua paths.
- A documented module pattern is to export `apply_to_config(config)` from helper files and invoke it from `wezterm.lua`.
- `wezterm.config_dir` is the directory containing the active config, and `wezterm.config_file` is the full path to the active `wezterm.lua`.

## Reload Semantics

- `wezterm.add_to_config_reload_watch_list(path)` adds extra files to the reload watch list.
- Since WezTerm `20220807-113146-c2fee766`, `require`d Lua files are added to the watch list implicitly.
- `wezterm.reload_configuration()` immediately reloads config, but only call it from an event or timer callback. Calling it at file scope creates an infinite reload loop.

## Callbacks and Events

- `wezterm.on(event_name, callback)` registers predefined or custom event handlers. Reloading the config rebuilds Lua state, so old handlers are cleared on reload.
- `wezterm.action_callback(callback)` is shorthand for registering a generated custom event and returning an action that emits it. Use it when custom behavior is tied to a specific key or action.
- `PromptInputLine` displays an input overlay and invokes a callback with `(window, pane, line)`. `line` can be `nil` if the prompt is cancelled.

## Startup and Workspace Patterns

- Use `gui-startup` for GUI startup window creation and initial workspace setup.
- Use `wezterm.mux.spawn_window(...)` and related mux APIs for workspace-aware startup flows instead of shelling out.
- Prefer official pane/window methods such as `window:perform_action(...)`, `window:active_workspace()`, `mux.get_workspace_names()`, and `mux.set_active_workspace(...)` for workspace logic.

## Local Validation

- Fast headless load check:
  - `wezterm --config-file ~/.config/wezterm/wezterm.lua show-keys`
- Live mux inspection when a GUI instance is already running:
  - `wezterm cli list`
  - `wezterm cli list-clients`
- Local machine note:
  - The installed version observed while creating this skill was `wezterm 20240203-110809-5046fc22`, which supports `config_builder`, `action_callback`, `PromptInputLine`, and `reload_configuration`.

## Official Sources

- Config files and module layout: https://wezterm.org/config/files.html
- `wezterm.config_builder`: https://wezterm.org/config/lua/wezterm/config_builder.html
- `wezterm.on`: https://wezterm.org/config/lua/wezterm/on.html
- `wezterm.action_callback`: https://wezterm.org/config/lua/wezterm/action_callback.html
- `wezterm.add_to_config_reload_watch_list`: https://wezterm.org/config/lua/wezterm/add_to_config_reload_watch_list.html
- `wezterm.reload_configuration`: https://wezterm.org/config/lua/wezterm/reload_configuration.html
- `wezterm.config_dir`: https://wezterm.org/config/lua/wezterm/config_dir.html
- `wezterm.config_file`: https://wezterm.org/config/lua/wezterm/config_file.html
- `gui-startup`: https://wezterm.org/config/lua/gui-events/gui-startup.html
- `PromptInputLine`: https://wezterm.org/config/lua/keyassignment/PromptInputLine.html
