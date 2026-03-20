try %{ declare-option str tmux_repl_id }
try %{ declare-option -hidden bool agent_submit false }

define-command \
    -docstring 'auto-detect Claude/Codex tmux pane and set tmux_repl_id' \
    agent-select-pane %{
    evaluate-commands %sh{
    kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
    detect_provider_for_pid() {
        if pgrep -P "$1" -x claude >/dev/null 2>&1; then
            printf 'claude\n'
            return 0
        fi
        if pgrep -P "$1" -x codex >/dev/null 2>&1; then
            printf 'codex\n'
            return 0
        fi
        return 1
    }
    list_agent_panes() {
        self="${kak_client_env_TMUX_PANE:-__no_self__}"
        while IFS=' ' read -r id pid idx; do
            [ "$id" = "$self" ] && continue
            provider=$(detect_provider_for_pid "$pid") || continue
            printf '%s\t%s\t%s\n' "$id" "$idx" "$provider"
        done <<EOF
$(tmux list-panes -F '#{pane_id} #{pane_pid} #{pane_index}' 2>/dev/null)
EOF
    }

    panes=$(list_agent_panes)

    if [ -z "$panes" ]; then
        printf "fail 'No Claude or Codex pane found in current tmux window'\n"
        exit 0
    fi

    count=$(printf '%s\n' "$panes" | grep -c .)

    if [ "$count" -eq 1 ]; then
        pane_id=$(printf '%s\n' "$panes" | awk -F '\t' 'NR==1 {print $1}')
        pane_idx=$(printf '%s\n' "$panes" | awk -F '\t' 'NR==1 {print $2}')
        pane_provider=$(printf '%s\n' "$panes" | awk -F '\t' 'NR==1 {print $3}')
        printf 'set-option current tmux_repl_id %s\n' "$(kakquote "$pane_id")"
        printf "echo -markup '{Information}Selected %s pane %s (index %s)'\n" \
            "$pane_provider" "$pane_id" "$pane_idx"
    else
        menu_cmd="menu"
        tmpfile=$(mktemp /tmp/kak-agent-panes.XXXXXX)
        printf '%s\n' "$panes" > "$tmpfile"
        while IFS= read -r line; do
            p=$(printf '%s' "$line" | awk -F '\t' '{print $1}')
            idx=$(printf '%s' "$line" | awk -F '\t' '{print $2}')
            provider=$(printf '%s' "$line" | awk -F '\t' '{print $3}')
            menu_cmd="${menu_cmd} $(kakquote "pane ${p} (index ${idx}, ${provider})") $(kakquote "set-option current tmux_repl_id '${p}'")"
        done < "$tmpfile"
        rm -f "$tmpfile"
        printf '%s\n' "$menu_cmd"
    fi
    }
}

define-command \
    -docstring 'send selection (or @file) to Claude/Codex tmux pane' \
    agent-send %{
    evaluate-commands %sh{
    kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
    detect_provider_for_pid() {
        if pgrep -P "$1" -x claude >/dev/null 2>&1; then
            printf 'claude\n'
            return 0
        fi
        if pgrep -P "$1" -x codex >/dev/null 2>&1; then
            printf 'codex\n'
            return 0
        fi
        return 1
    }
    detect_provider_for_pane() {
        pane_pid=$(tmux list-panes -a -F '#{pane_id} #{pane_pid}' 2>/dev/null \
            | awk -v pane="$1" '$1 == pane { print $2; exit }')
        [ -n "$pane_pid" ] || return 1
        detect_provider_for_pid "$pane_pid"
    }
    list_agent_panes() {
        self="${kak_client_env_TMUX_PANE:-__no_self__}"
        while IFS=' ' read -r id pid idx; do
            [ "$id" = "$self" ] && continue
            provider=$(detect_provider_for_pid "$pid") || continue
            printf '%s\t%s\t%s\n' "$id" "$idx" "$provider"
        done <<EOF
$(tmux list-panes -F '#{pane_id} #{pane_pid} #{pane_index}' 2>/dev/null)
EOF
    }

    # Validate / auto-detect pane
    pane_id="$kak_opt_tmux_repl_id"
    pane_provider=""
    if [ -n "$pane_id" ]; then
        pane_provider=$(detect_provider_for_pane "$pane_id" 2>/dev/null || true)
    fi
    if [ -z "$pane_id" ] || [ -z "$pane_provider" ]; then
        panes=$(list_agent_panes)
        if [ -z "$panes" ]; then
            printf "fail 'No Claude or Codex pane found in current tmux window'\n"
            exit 0
        fi
        count=$(printf '%s\n' "$panes" | grep -c .)
        if [ "$count" -eq 1 ]; then
            pane_id=$(printf '%s\n' "$panes" | awk -F '\t' 'NR==1 {print $1}')
            pane_provider=$(printf '%s\n' "$panes" | awk -F '\t' 'NR==1 {print $3}')
            printf 'set-option current tmux_repl_id %s\n' "$(kakquote "$pane_id")"
        else
            if [ "$kak_opt_agent_submit" = "true" ]; then
                after_select="agent-send-submit"
            else
                after_select="agent-send"
            fi
            menu_cmd="menu"
            tmpfile=$(mktemp /tmp/kak-agent-panes.XXXXXX)
            printf '%s\n' "$panes" > "$tmpfile"
            while IFS= read -r line; do
                p=$(printf '%s' "$line" | awk -F '\t' '{print $1}')
                idx=$(printf '%s' "$line" | awk -F '\t' '{print $2}')
                provider=$(printf '%s' "$line" | awk -F '\t' '{print $3}')
                menu_cmd="${menu_cmd} $(kakquote "pane ${p} (index ${idx}, ${provider})") $(kakquote "set-option current tmux_repl_id '${p}'; ${after_select}")"
            done < "$tmpfile"
            rm -f "$tmpfile"
            printf '%s\n' "$menu_cmd"
            exit 0
        fi
    fi

    # Build message
    sel_desc="$kak_selection_desc"
    anchor="${sel_desc%%,*}"
    cursor="${sel_desc#*,}"
    buffile="$kak_buffile"

    if [ "$anchor" = "$cursor" ]; then
        # Single-char cursor — send file reference only
        if [ -z "$buffile" ]; then
            printf "fail 'No file in current buffer'\n"
            exit 0
        fi
        message="@${buffile}"
    else
        # Real selection
        anchor_line="${anchor%%.*}"
        cursor_line="${cursor%%.*}"
        if [ "$anchor_line" -le "$cursor_line" ]; then
            start_line="$anchor_line"; end_line="$cursor_line"
        else
            start_line="$cursor_line"; end_line="$anchor_line"
        fi
        if [ -n "$buffile" ]; then
            ext="${buffile##*.}"
            [ "$ext" = "$buffile" ] && ext=""
            if [ "$start_line" = "$end_line" ]; then
                loc="line ${start_line}"
            else
                loc="lines ${start_line}-${end_line}"
            fi
            message="In \`${buffile}\` ${loc}:
\`\`\`${ext}
${kak_selection}
\`\`\`"
        else
            message="${kak_selection}"
        fi
    fi

    # Send via tmux bracketed paste
    tmux set-buffer -b kak_agent -- "$message" >/dev/null \
        && tmux paste-buffer -b kak_agent -t "$pane_id" -p >/dev/null
    if [ "$kak_opt_agent_submit" = "true" ]; then
        sleep 0.1
        tmux send-keys -t "$pane_id" Enter
    fi
    printf "echo -markup '{Information}Sent to %s (%s)'\n" "$pane_provider" "$pane_id"
    }
}

define-command \
    -docstring 'send selection (or @file) to Claude/Codex tmux pane and submit' \
    agent-send-submit %{
    set-option current agent_submit true
    agent-send
    set-option current agent_submit false
}
