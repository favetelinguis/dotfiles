try %{ declare-option -hidden str note_root '' }

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

        output=$(git -C "$root" commit -m "$commit_msg" -- "$relpath" 2>&1)
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
                output=$(git -C "$root" commit -m "Create note $filename" -- "$filename" 2>&1)
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
                output=$(git -C "$root" commit -m "Create note todo.md" -- "todo.md" 2>&1)
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
            output=$(git -C "$root" commit -m "Delete note $filename" -- "$relpath" 2>&1)
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
    note-ensure-root
    evaluate-commands %sh{
        session="$kak_session"
        client="$kak_client"
        root="$kak_opt_note_root"
        tmp=$(mktemp /tmp/kak-note-list-XXXXXX)
        root_q=$(printf '%s' "$root" | sed "s/'/'\\\\''/g")

        cat > "$tmp" << SHELL
#!/bin/sh
root='$root_q'
cd "\$root" || exit 1
result=\$( (fd --type f --exclude todo.md . 2>/dev/null || find . -type f ! -name todo.md | sed 's#^\./##') | fzf --reverse --border --prompt 'notes> ')
[ -z "\$result" ] && rm -f "$tmp" && exit
kak_path=\$(printf '%s' "\$root/\$result" | sed "s/'/''/g")
printf "evaluate-commands -client '$client' 'edit -existing ''%s'''\n" "\$kak_path" | kak -p '$session'
rm -f "$tmp"
SHELL

        chmod +x "$tmp"
        kak_tmp=$(printf '%s' "$tmp" | sed "s/'/''/g")
        printf "tmux-terminal-vertical sh '%s'\n" "$kak_tmp"
    }
}

define-command \
    -docstring 'live-grep notes and jump to a match' \
    note-grep %{
    note-ensure-root
    evaluate-commands %sh{
        session="$kak_session"
        client="$kak_client"
        root="$kak_opt_note_root"
        tmp=$(mktemp /tmp/kak-note-grep-XXXXXX)
        root_q=$(printf '%s' "$root" | sed "s/'/'\\\\''/g")

        cat > "$tmp" << SHELL
#!/bin/sh
root='$root_q'
cd "\$root" || exit 1
result=\$(rg --line-number --no-heading --with-filename --smart-case --glob '!todo.md' -- '' . | \
    fzf --disabled --reverse --border --prompt 'notes grep> ' \
        --bind 'change:reload:rg --line-number --no-heading --with-filename --smart-case --glob '"'"'!todo.md'"'"' -- {q} . || true')
[ -z "\$result" ] && rm -f "$tmp" && exit
filepath=\$(printf '%s' "\$result" | cut -d: -f1)
lineno=\$(printf '%s' "\$result" | cut -d: -f2)
filepath=\${filepath#./}
kak_path=\$(printf '%s' "\$root/\$filepath" | sed "s/'/''/g")
printf "evaluate-commands -client '$client' 'edit -existing ''%s'' %s'\n" "\$kak_path" "\$lineno" | kak -p '$session'
rm -f "$tmp"
SHELL

        chmod +x "$tmp"
        kak_tmp=$(printf '%s' "$tmp" | sed "s/'/''/g")
        printf "tmux-terminal-vertical sh '%s'\n" "$kak_tmp"
    }
}

hook global BufOpenFile .* %{ note-buffer-sync-state }
hook global BufNewFile  .* %{ note-buffer-sync-state }

try %{ declare-user-mode note }
map global user n ':enter-user-mode note<ret>' -docstring 'notes'
map global note n ':note-create<ret>'          -docstring 'create note'
map global note t ':note-todo-open<ret>'       -docstring 'open todo'
map global note f ':note-list<ret>'            -docstring 'list notes'
map global note g ':note-grep<ret>'            -docstring 'grep notes'
map global note X ':note-delete-current<ret>'  -docstring 'delete note'
