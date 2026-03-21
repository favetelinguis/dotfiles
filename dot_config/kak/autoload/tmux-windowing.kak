define-command -params .. -docstring '
split [<commands>]: create a new Kakoune client in a vertical tmux split
The new client attaches to the current Kakoune session' \
split %{
    # Requires the symlinked upstream tmux windowing module.
    tmux-terminal-vertical kak -c %val{session} -e "%arg{@}"
}
complete-command -menu split command

define-command -params .. -docstring '
vsplit [<commands>]: create a new Kakoune client in a horizontal tmux split
The new client attaches to the current Kakoune session' \
vsplit %{
    tmux-terminal-horizontal kak -c %val{session} -e "%arg{@}"
}
complete-command -menu vsplit command

define-command -params .. -docstring '
tabnew [<commands>]: create a new Kakoune client in a new tmux window
The new client attaches to the current Kakoune session' \
tabnew %{
    tmux-terminal-window kak -c %val{session} -e "%arg{@}"
}
complete-command -menu tabnew command
