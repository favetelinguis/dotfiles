define-command -hidden -params 2 global-open-query %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        action=$1
        query=$2
        helper_path="${HOME}/.local/bin/kak-picker-global"

        [ -x "$helper_path" ] || {
            printf "fail %s\n" "$(kakquote "GNU Global picker helper not found: $helper_path")"
            exit
        }

        case "$action" in
            smart)
                command_name='global-goto-definition'
                no_matches_prefix='no GNU Global matches found for'
                ;;
            references)
                command_name='global-find-references'
                no_matches_prefix='no GNU Global references found for'
                ;;
            callers)
                command_name='global-find-callers'
                no_matches_prefix='no GNU Global callers found for'
                ;;
            symbol)
                command_name='global-search-symbol'
                no_matches_prefix='no GNU Global symbol matches found for'
                ;;
            *)
                printf "fail %s\n" "$(kakquote "unsupported GNU Global action: $action")"
                exit
                ;;
        esac

        case "$action" in
            smart|references|callers)
                [ -n "$kak_buffile" ] || {
                    printf "fail %s\n" "$(kakquote "${command_name} requires a file-backed buffer")"
                    exit
                }
                context_path=$kak_buffile
                line=$kak_cursor_line
                ;;
            symbol)
                context_path=$PWD
                line=${kak_cursor_line:-1}
                if [ -n "${kak_buffile:-}" ]; then
                    context_path=$kak_buffile
                fi
                ;;
        esac

        [ -n "$query" ] || {
            printf "fail %s\n" "$(kakquote "no GNU Global query provided")"
            exit
        }

        results=$(
            KAK_GLOBAL_ACTION="$action" \
            KAK_GLOBAL_FILE="$context_path" \
            KAK_GLOBAL_LINE="$line" \
            KAK_GLOBAL_SYMBOL="$query" \
            "$helper_path" --list 2>&1
        )
        status=$?
        if [ $status -ne 0 ]; then
            printf "fail %s\n" "$(kakquote "$(printf '%s' "$results" | tr '\n' ' ')")"
            exit
        fi

        first=$(printf '%s\n' "$results" | sed -n '1p')
        second=$(printf '%s\n' "$results" | sed -n '2p')

        [ -n "$first" ] || {
            printf "fail %s\n" "$(kakquote "$no_matches_prefix $query")"
            exit
        }

        if [ -z "$second" ]; then
            filepath=$(printf '%s' "$first" | cut -d: -f1)
            lineno=$(printf '%s' "$first" | cut -d: -f2)

            [ -n "$filepath" ] || {
                printf "fail %s\n" "$(kakquote "unable to parse GNU Global result for $query")"
                exit
            }
            [ -n "$lineno" ] || {
                printf "fail %s\n" "$(kakquote "unable to parse GNU Global line number for $query")"
                exit
            }

            printf "edit -existing %s %s\n" "$(kakquote "$filepath")" "$lineno"
            exit
        fi

        [ -n "$TMUX" ] || {
            printf "fail %s\n" "$(kakquote "multiple GNU Global matches require Kakoune inside tmux for the fzf picker")"
            exit
        }

        results_file=$(mktemp "${TMPDIR:-/tmp}/kak-global-results.XXXXXX") || {
            printf "fail %s\n" "$(kakquote "unable to create a temporary GNU Global results file")"
            exit
        }
        printf '%s\n' "$results" >"$results_file" || {
            rm -f "$results_file"
            printf "fail %s\n" "$(kakquote "unable to store GNU Global results")"
            exit
        }

        tmp=$(mktemp "${TMPDIR:-/tmp}/kak-global-picker.XXXXXX") || {
            rm -f "$results_file"
            printf "fail %s\n" "$(kakquote "unable to create a temporary GNU Global picker launcher")"
            exit
        }

        session_q=$(printf '%s' "$kak_session" | sed "s/'/'\\\\''/g")
        client_q=$(printf '%s' "$kak_client" | sed "s/'/'\\\\''/g")
        pane_q=$(printf '%s' "${kak_client_env_TMUX_PANE:-}" | sed "s/'/'\\\\''/g")
        helper_q=$(printf '%s' "$helper_path" | sed "s/'/'\\\\''/g")
        results_q=$(printf '%s' "$results_file" | sed "s/'/'\\\\''/g")
        cwd_q=$(printf '%s' "$PWD" | sed "s/'/'\\\\''/g")

        cat >"$tmp" << SHELL
#!/bin/sh
export KAK_PICKER_SESSION='$session_q'
export KAK_PICKER_CLIENT='$client_q'
export KAK_PICKER_ORIGINAL_PANE='$pane_q'
export KAK_GLOBAL_ACTION='$action'
export KAK_GLOBAL_RESULTS_FILE='$results_q'
cd '$cwd_q' || exit 1
'$helper_q'
status=\$?
rm -f '$tmp' '$results_q'
exit "\$status"
SHELL

        chmod +x "$tmp"
        printf "tmux-terminal-vertical sh %s\n" "$(kakquote "$tmp")"
    }
}

define-command -docstring 'smart goto for the symbol under the cursor using GNU Global' global-goto-definition %{
    execute-keys <a-i>w
    global-open-query smart %val{selection}
}

define-command -docstring 'find references to the symbol under the cursor using GNU Global' global-find-references %{
    execute-keys <a-i>w
    global-open-query references %val{selection}
}

define-command -docstring 'find callers of the symbol under the cursor using GNU Global references' global-find-callers %{
    execute-keys <a-i>w
    global-open-query callers %val{selection}
}

define-command -hidden global-search-symbol-from-prompt %{
    global-open-query symbol %val{text}
}

define-command -docstring 'search for a symbol name with GNU Global and jump to a match' global-search-symbol %{
    execute-keys <a-i>w
    prompt -init %val{selection} 'global symbol: ' %{ global-search-symbol-from-prompt }
}

define-command -docstring 'jump backward in the Kakoune jump list' global-jump-back %{
    execute-keys <c-o>
}

define-command -docstring 'show GNU Global callee search limitation' global-find-callees %{
    fail 'GNU Global does not implement callee search; use g d on a callsite or g s to search manually'
}

define-command -docstring 'incrementally update GNU Global tag files for the current project' global-update-tags %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        command -v global >/dev/null 2>&1 || {
            printf "fail %s\n" "$(kakquote "global command not found in PATH")"
            exit
        }

        context_path=$PWD
        if [ -n "$kak_buffile" ]; then
            context_path=$kak_buffile
        fi

        if [ -d "$context_path" ]; then
            context_dir=$context_path
        else
            context_dir=${context_path%/*}
        fi

        project_root=$(global -C "$context_dir" --print root 2>/dev/null || true)
        [ -n "$project_root" ] || {
            printf "fail %s\n" "$(kakquote "no GTAGS database found from $context_dir")"
            exit
        }

        output=$(global -C "$project_root" -u 2>&1)
        status=$?
        if [ $status -ne 0 ]; then
            printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
            exit
        fi

        if [ -n "$output" ]; then
            printf "echo -markup '{Information}%s'\n" "$(printf '%s' "$output" | tr '\n' ' ' | sed "s/'/''/g")"
        else
            printf "echo -markup '{Information}GNU Global tags updated for %s'\n" "$(printf '%s' "$project_root" | sed "s/'/''/g")"
        fi
    }
}
