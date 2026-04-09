-- Requirements
-- 1. Prompt to select to a number and send text to that number and remember that number
-- if the pane is closed promt for numbers again.
-- 2. Open a new split following the emacs other window if one open side if 2 vertical open horizontal
-- if two horizontal open vertical etc.
-- 3. Send to window with specific process running, if multiple panes run that process promt to select one.
--
-- How to handle metadata such as file line col
-- Include an option to add \r

local wezterm = require("wezterm")
local act = wezterm.action

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s)
	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

wezterm.on("user-var-changed", function(window, pane, name, value)
	if name ~= "my_action" then
		return
	end

	local command = wezterm.json_parse(value)
	local choices = {}

	for _, item in ipairs(pane:tab():panes_with_info()) do
		if item.is_active then
			goto continue
		end
		local target_pane = item.pane
		local pane_id = target_pane:pane_id()
		local process_name = basename(target_pane:get_foreground_process_name())
		local title = target_pane:get_title() or ""

		table.insert(choices, {
			id = tostring(pane_id),
			label = string.format(
				"Pane %d | %s | %s",
				pane_id,
				process_name ~= "" and process_name or "unknown process",
				title ~= "" and title or "no_title"
			),
		})
		::continue::
	end

	window:perform_action(
		act.InputSelector({
			title = "Select pane",
			description = "Choose the pane that should receive text",
			choices = choices,
			fuzzy = true,
			fuzzy_description = "Search by pane id, process, or title: ",
			action = wezterm.action_callback(function(inner_window, _inner_pane, id, _label)
				if not id then
					return
				end

				local target_id = tonumber(id)
				if not target_id then
					return
				end

				for _, info in ipairs(pane:tab():panes_with_info()) do
					if info.pane:pane_id() == target_id then
						-- info.pane:send_text(command.hello or "MISSING")
						info.pane:paste(command.hello or "MISSING")
						return
					end
				end
			end),
		}),
		pane
	)
end)
