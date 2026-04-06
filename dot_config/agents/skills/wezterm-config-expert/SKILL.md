---
name: wezterm-config-expert
description: Write, edit, review, and debug WezTerm Lua configuration and helper modules. Use when tasks touch `~/.wezterm.lua`, `~/.config/wezterm/wezterm.lua`, `~/.config/wezterm/*.lua`, or other Lua modules required from a WezTerm config, including key bindings, mouse bindings, launch menu entries, appearance settings, callbacks, custom events, startup/workspace logic, mux helpers, and config reload behavior. Use alongside `chezmoi-dotfile-expert` whenever the WezTerm config is managed in chezmoi or should be moved into chezmoi source state.
---

# WezTerm Config Expert

## Overview

Use this skill for WezTerm-specific Lua, not generic Lua. Prefer documented WezTerm APIs, events, and config options over ad hoc shelling-out or homegrown abstractions.

## Workflow

1. Resolve the active config entrypoint and version first.
- Identify whether the config comes from `~/.wezterm.lua`, `~/.config/wezterm/wezterm.lua`, `--config-file`, or `$WEZTERM_CONFIG_FILE`.
- Inspect the required helper modules before editing so the composition root and module boundaries stay coherent.
- Check `wezterm --version` before relying on version-gated APIs such as `config_builder`, `action_callback`, `PromptInputLine`, or `reload_configuration`.

2. Preserve the reload model.
- Expect the config to be evaluated multiple times at startup and on reload.
- Keep top-level code idempotent and avoid side effects there.
- Put startup actions, pane/window spawning, timers, and other imperative behavior behind `wezterm.on(...)`, `wezterm.action_callback(...)`, or explicit user actions.
- Use `wezterm.reload_configuration()` only from callbacks; never at file scope.

3. Structure multi-file configs the WezTerm way.
- Prefer `require "module_name"` from files placed under `~/.config/wezterm/*.lua` or `~/.wezterm/*.lua`.
- For modules that mutate config, prefer exporting `apply_to_config(config)`.
- For modules that expose actions or stateful helpers, return a table of focused functions.
- If code reads extra files without `require`, register those paths with `wezterm.add_to_config_reload_watch_list(...)` so automatic reloads notice them.

4. Prefer native WezTerm primitives.
- Use `local wezterm = require("wezterm")`, `local act = wezterm.action`, and `local config = wezterm.config_builder()` on current releases.
- Guard `config_builder` only when compatibility with older WezTerm builds actually matters.
- Prefer documented key assignments, pane/window methods, mux APIs, and events over spawning shell commands to simulate native behavior.
- For custom key-driven behavior, either pair `act.EmitEvent(...)` with `wezterm.on(...)` or use `wezterm.action_callback(...)` when the behavior is local to one binding.

5. Validate headlessly first, then in the GUI.
- Run `wezterm --config-file <path-to-wezterm.lua> show-keys` after edits. It loads the config and catches parse/load errors without launching the GUI.
- If the change affects startup, workspaces, rendering, or GUI-only events, test it in a real WezTerm instance after the headless check.
- Use `wezterm cli list` and `wezterm cli list-clients` only when a GUI or mux server is already running and the task depends on live state.

## References

- Read [references/wezterm-docs.md](references/wezterm-docs.md) before changing file discovery, reload behavior, module layout, callbacks, or mux startup logic.
