try %{ declare-option -hidden str note_root '' }
try %{ declare-option -hidden str note_history_return_buffer '' }
try %{ declare-option -hidden str note_history_return_cursor '' }

evaluate-commands %sh{
    kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

    printf "set-option global note_root %s\n" "$(kakquote "$HOME/kak_notes")"
}

define-command -hidden note-ensure-root %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        root=$kak_opt_note_root

        mkdir -p "$root" 2>/dev/null || {
            printf "fail %s\n" "$(kakquote "unable to create notes directory $root")"
            exit
        }

        if [ ! -d "$root/.git" ]; then
            output=$(git -C "$root" init 2>&1)
            status=$?
            if [ $status -ne 0 ]; then
                printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
                exit
            fi
        fi
    }
}

define-command -hidden note-buffer-sync-state %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        buffile=$kak_buffile
        root=$kak_opt_note_root

        printf "remove-hooks buffer note-auto-commit\n"

        [ -n "$buffile" ] || exit
        [ -n "$root" ] || exit

        case "$buffile" in
            "$root"/*) ;;
            *) exit ;;
        esac

        printf "hook -group note-auto-commit buffer BufWritePost .* %%{ note-commit-current }\n"
    }
}

define-command -hidden note-commit-current %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        buffile=$kak_buffile
        root=$kak_opt_note_root

        [ -n "$buffile" ] || exit
        [ -n "$root" ] || exit

        case "$buffile" in
            "$root"/*) ;;
            *) exit ;;
        esac

        relpath=${buffile#"$root"/}
        filename=$(basename "$relpath")

        if git -C "$root" ls-files --error-unmatch -- "$relpath" >/dev/null 2>&1; then
            commit_msg="Update note $filename"
        else
            commit_msg="Create note $filename"
        fi

        output=$(git -C "$root" add -- "$relpath" 2>&1)
        status=$?
        if [ $status -ne 0 ]; then
            printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
            exit
        fi

        if git -C "$root" diff --cached --quiet -- "$relpath"; then
            exit
        fi

        output=$(git -C "$root" commit --no-verify -m "$commit_msg" -- "$relpath" 2>&1)
        status=$?
        if [ $status -ne 0 ]; then
            printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
            exit
        fi
    }
}

define-command -hidden note-create-from-prompt %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        raw=$kak_text
        root=$kak_opt_note_root

        case "$raw" in
            *[![:alnum:][:space:]]*)
                printf "fail %s\n" "$(kakquote "note names may only contain letters, digits, and whitespace")"
                exit
                ;;
        esac

        normalized=$(printf '%s' "$raw" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')
        if [ -z "$normalized" ]; then
            printf "fail %s\n" "$(kakquote "note name cannot be empty")"
            exit
        fi

        filename=$(printf '%s' "$normalized" | tr ' ' '_').md
        filepath=$root/$filename

        mkdir -p "$root" 2>/dev/null || {
            printf "fail %s\n" "$(kakquote "unable to create notes directory $root")"
            exit
        }

        if [ ! -d "$root/.git" ]; then
            output=$(git -C "$root" init 2>&1)
            status=$?
            if [ $status -ne 0 ]; then
                printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
                exit
            fi
        fi

        if [ ! -e "$filepath" ]; then
            : > "$filepath" || {
                printf "fail %s\n" "$(kakquote "unable to create note $filepath")"
                exit
            }

            output=$(git -C "$root" add -- "$filename" 2>&1)
            status=$?
            if [ $status -ne 0 ]; then
                printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
                exit
            fi

            if ! git -C "$root" diff --cached --quiet -- "$filename"; then
                output=$(git -C "$root" commit --no-verify -m "Create note $filename" -- "$filename" 2>&1)
                status=$?
                if [ $status -ne 0 ]; then
                    printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
                    exit
                fi
            fi
        fi

        printf "edit -existing %s\n" "$(kakquote "$filepath")"
    }
}

define-command \
    -docstring 'prompt for a note name, normalize it, and open the note' \
    note-create %{
    prompt 'note name: ' %{ note-create-from-prompt }
}

define-command \
    -docstring 'open the notes todo file' \
    note-todo-open %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        root=$kak_opt_note_root
        filepath=$root/todo.md

        mkdir -p "$root" 2>/dev/null || {
            printf "fail %s\n" "$(kakquote "unable to create notes directory $root")"
            exit
        }

        if [ ! -d "$root/.git" ]; then
            output=$(git -C "$root" init 2>&1)
            status=$?
            if [ $status -ne 0 ]; then
                printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
                exit
            fi
        fi

        if [ ! -e "$filepath" ]; then
            : > "$filepath" || {
                printf "fail %s\n" "$(kakquote "unable to create note $filepath")"
                exit
            }

            output=$(git -C "$root" add -- "todo.md" 2>&1)
            status=$?
            if [ $status -ne 0 ]; then
                printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
                exit
            fi

            if ! git -C "$root" diff --cached --quiet -- "todo.md"; then
                output=$(git -C "$root" commit --no-verify -m "Create note todo.md" -- "todo.md" 2>&1)
                status=$?
                if [ $status -ne 0 ]; then
                    printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
                    exit
                fi
            fi
        fi

        printf "edit -existing %s\n" "$(kakquote "$filepath")"
    }
}

define-command -hidden -params 2 note-launch-picker %{
    note-ensure-root
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        helper=$1
        tmp_prefix=$2
        helper_path="${HOME}/.local/bin/${helper}"
        root=$kak_opt_note_root

        [ -x "$helper_path" ] || {
            printf "fail %s\n" "$(kakquote "note helper not found: $helper_path")"
            exit
        }

        tmp=$(mktemp "${TMPDIR:-/tmp}/${tmp_prefix}.XXXXXX") || {
            printf "fail %s\n" "$(kakquote "unable to create a temporary picker script")"
            exit
        }

        session_q=$(printf '%s' "$kak_session" | sed "s/'/'\\\\''/g")
        client_q=$(printf '%s' "$kak_client" | sed "s/'/'\\\\''/g")
        pane_q=$(printf '%s' "${kak_client_env_TMUX_PANE:-}" | sed "s/'/'\\\\''/g")
        helper_q=$(printf '%s' "$helper_path" | sed "s/'/'\\\\''/g")
        root_q=$(printf '%s' "$root" | sed "s/'/'\\\\''/g")

        cat >"$tmp" << SHELL
#!/bin/sh
export KAK_PICKER_SESSION='$session_q'
export KAK_PICKER_CLIENT='$client_q'
export KAK_PICKER_ORIGINAL_PANE='$pane_q'
export KAK_NOTE_ROOT='$root_q'
'$helper_q'
status=\$?
rm -f '$tmp'
exit "\$status"
SHELL

        chmod +x "$tmp"
        printf "tmux-terminal-vertical sh %s\n" "$(kakquote "$tmp")"
    }
}

define-command -hidden -params 3 note-launch-history-picker %{
    note-ensure-root
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        helper=$1
        tmp_prefix=$2
        relpath=$3
        helper_path="${HOME}/.local/bin/${helper}"
        root=$kak_opt_note_root

        [ -x "$helper_path" ] || {
            printf "fail %s\n" "$(kakquote "note helper not found: $helper_path")"
            exit
        }

        tmp=$(mktemp "${TMPDIR:-/tmp}/${tmp_prefix}.XXXXXX") || {
            printf "fail %s\n" "$(kakquote "unable to create a temporary picker script")"
            exit
        }

        session_q=$(printf '%s' "$kak_session" | sed "s/'/'\\\\''/g")
        client_q=$(printf '%s' "$kak_client" | sed "s/'/'\\\\''/g")
        pane_q=$(printf '%s' "${kak_client_env_TMUX_PANE:-}" | sed "s/'/'\\\\''/g")
        helper_q=$(printf '%s' "$helper_path" | sed "s/'/'\\\\''/g")
        root_q=$(printf '%s' "$root" | sed "s/'/'\\\\''/g")
        relpath_q=$(printf '%s' "$relpath" | sed "s/'/'\\\\''/g")

        cat >"$tmp" << SHELL
#!/bin/sh
export KAK_PICKER_SESSION='$session_q'
export KAK_PICKER_CLIENT='$client_q'
export KAK_PICKER_ORIGINAL_PANE='$pane_q'
export KAK_NOTE_ROOT='$root_q'
export KAK_NOTE_HISTORY_RELPATH='$relpath_q'
'$helper_q'
status=\$?
rm -f '$tmp'
exit "\$status"
SHELL

        chmod +x "$tmp"
        printf "tmux-terminal-vertical sh %s\n" "$(kakquote "$tmp")"
    }
}

define-command -hidden -params 3 note-history-open %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        kakline() { printf '%s' "$1" | tr '\n' ' ' | sed "s/'/''/g"; }

        commit=$1
        path_at_commit=$2
        lineno=$3
        root=$kak_opt_note_root
        origin_buffer=$kak_bufname
        origin_cursor="${kak_cursor_line}.${kak_cursor_column}"
        origin_filetype=$kak_opt_filetype

        [ -n "$commit" ] || {
            printf "fail %s\n" "$(kakquote "note-history-open requires a commit id")"
            exit
        }
        [ -n "$path_at_commit" ] || {
            printf "fail %s\n" "$(kakquote "note-history-open requires a file path")"
            exit
        }
        [ -n "$root" ] || {
            printf "fail %s\n" "$(kakquote "notes directory is not configured")"
            exit
        }

        case "$lineno" in
            ''|*[!0-9]*)
                lineno=1
                ;;
        esac

        short_hash=$(printf '%s' "$commit" | cut -c1-8)
        tmp=$(mktemp /tmp/kak-note-history-XXXXXX) || {
            printf "fail %s\n" "$(kakquote "unable to create a temporary history buffer")"
            exit
        }

        if ! git -C "$root" show "$commit:$path_at_commit" >"$tmp" 2>/dev/null; then
            rm -f "$tmp"
            printf "fail %s\n" "$(kakquote "unable to load $path_at_commit at $short_hash")"
            exit
        fi

        printf "edit -existing %s %s\n" "$(kakquote "$tmp")" "$lineno"
        if [ -n "$origin_filetype" ]; then
            printf "set-option buffer filetype %s\n" "$(kakquote "$origin_filetype")"
        fi
        printf "set-option buffer readonly true\n"
        printf "set-option buffer note_history_return_buffer %s\n" "$(kakquote "$origin_buffer")"
        printf "set-option buffer note_history_return_cursor %s\n" "$(kakquote "$origin_cursor")"
        printf "map buffer normal q ':note-history-close<ret>' -docstring %s\n" \
            "$(kakquote "close note history buffer")"
        printf "echo -markup '{Information}%s'\n" \
            "$(kakline "$path_at_commit @ $short_hash")"
    }
}

define-command -hidden note-history-close %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        origin_buffer=$kak_opt_note_history_return_buffer
        origin_cursor=$kak_opt_note_history_return_cursor
        current_buffer=$kak_bufname

        if [ -n "$origin_buffer" ]; then
            printf "try %%{ buffer %s }\n" "$(kakquote "$origin_buffer")"
            if [ -n "$origin_cursor" ]; then
                printf "try %%{ select %s,%s }\n" "$origin_cursor" "$origin_cursor"
            fi
        fi
        printf "nop %%sh{ rm -f %s }\n" "$(kakquote "$current_buffer")"
        printf "delete-buffer! %s\n" "$(kakquote "$current_buffer")"
    }
}

define-command \
    -docstring 'delete the current note and commit the deletion' \
    note-delete-current %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        buffile=$kak_buffile
        root=$kak_opt_note_root

        [ -n "$buffile" ] || {
            printf "fail %s\n" "$(kakquote "current buffer is not a file")"
            exit
        }
        [ -n "$root" ] || {
            printf "fail %s\n" "$(kakquote "notes directory is not configured")"
            exit
        }

        case "$buffile" in
            "$root"/*) ;;
            *)
                printf "fail %s\n" "$(kakquote "current file is not a note")"
                exit
                ;;
        esac

        if [ "$kak_modified" = "true" ]; then
            printf "fail %s\n" "$(kakquote "write the buffer before deleting the note")"
            exit
        fi

        relpath=${buffile#"$root"/}
        filename=$(basename "$relpath")

        if [ "$filename" = "todo.md" ]; then
            printf "fail %s\n" "$(kakquote "todo.md cannot be deleted with note-delete-current")"
            exit
        fi

        mkdir -p "$root" 2>/dev/null || {
            printf "fail %s\n" "$(kakquote "unable to create notes directory $root")"
            exit
        }

        if [ ! -d "$root/.git" ]; then
            output=$(git -C "$root" init 2>&1)
            status=$?
            if [ $status -ne 0 ]; then
                printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
                exit
            fi
        fi

        rm -f -- "$buffile" || {
            printf "fail %s\n" "$(kakquote "unable to delete note $buffile")"
            exit
        }

        output=$(git -C "$root" add -A -- "$relpath" 2>&1)
        status=$?
        if [ $status -ne 0 ]; then
            printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
            exit
        fi

        if ! git -C "$root" diff --cached --quiet -- "$relpath"; then
            output=$(git -C "$root" commit --no-verify -m "Delete note $filename" -- "$relpath" 2>&1)
            status=$?
            if [ $status -ne 0 ]; then
                printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
                exit
            fi
        fi

        printf "remove-hooks buffer note-auto-commit\n"
        printf "delete-buffer!\n"
    }
}

define-command \
    -docstring 'fuzzy-find a note and open it' \
    note-list %{
    note-launch-picker kak-note-list kak-note-list
}

define-command \
    -docstring 'live-grep notes and jump to a match' \
    note-grep %{
    note-launch-picker kak-note-grep kak-note-grep
}

define-command \
    -docstring 'live-grep the current note across its git history' \
    note-history-grep-file %{
    note-ensure-root
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        buffile=$kak_buffile
        root=$kak_opt_note_root

        [ -n "$buffile" ] || {
            printf "fail %s\n" "$(kakquote "current buffer is not a file")"
            exit
        }

        case "$buffile" in
            "$root"/*) ;;
            *)
                printf "fail %s\n" "$(kakquote "current file is not a note")"
                exit
                ;;
        esac

        relpath=${buffile#"$root"/}
        git -C "$root" ls-files --error-unmatch -- "$relpath" >/dev/null 2>&1 || {
            printf "fail %s\n" "$(kakquote "current note is not tracked by git")"
            exit
        }

        printf "note-launch-history-picker kak-note-history-file kak-note-history-file %s\n" \
            "$(kakquote "$relpath")"
    }
}

define-command \
    -docstring 'live-grep all notes across the notes git history' \
    note-history-grep-all %{
    note-launch-history-picker kak-note-history-all kak-note-history-all ''
}

hook global BufOpenFile .* %{ note-buffer-sync-state }
hook global BufNewFile  .* %{ note-buffer-sync-state }
