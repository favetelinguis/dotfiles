try %{ declare-option -hidden str chezmoi_source_root '' }
try %{ declare-option -hidden bool chezmoi_managed false }
try %{ declare-option -hidden str chezmoi_target '' }

evaluate-commands %sh{
    kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

    if ! command -v chezmoi >/dev/null 2>&1; then
        printf "fail %s\n" "$(kakquote "chezmoi command not found in PATH")"
        exit
    fi

    source_root=$(chezmoi source-path 2>/dev/null) || {
        printf "fail %s\n" "$(kakquote "unable to resolve chezmoi source directory")"
        exit
    }

    printf "set-option global chezmoi_source_root %s\n" "$(kakquote "$source_root")"
}

define-command -hidden chezmoi-buffer-sync-state %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        buffile=$kak_buffile
        source_root=$kak_opt_chezmoi_source_root

        printf "remove-hooks buffer chezmoi-auto-apply\n"
        printf "set-option buffer chezmoi_managed false\n"
        printf "set-option buffer chezmoi_target %s\n" "$(kakquote "")"

        [ -n "$buffile" ] || exit
        [ -n "$source_root" ] || exit

        case "$buffile" in
            "$source_root"/*) ;;
            *) exit ;;
        esac

        target=$(chezmoi target-path "$buffile" 2>/dev/null) || exit
        source_file=$(chezmoi source-path "$target" 2>/dev/null) || exit
        [ "$source_file" = "$buffile" ] || exit

        printf "set-option buffer chezmoi_managed true\n"
        printf "set-option buffer chezmoi_target %s\n" "$(kakquote "$target")"
        printf "hook -group chezmoi-auto-apply buffer BufWritePost .* %%{ chezmoi-apply-current }\n"
    }
}

define-command \
    -docstring 'fuzzy-find a managed chezmoi file and open its source state' \
    chezmoi-find %{
    evaluate-commands %sh{
        session="$kak_session"
        client="$kak_client"
        source_root="$kak_opt_chezmoi_source_root"
        tmp=$(mktemp /tmp/kak-chezmoi-find-XXXXXX)

        cat > "$tmp" << SHELL
#!/bin/sh
cd "$source_root" || exit 1
result=\$(chezmoi managed --include files --path-style absolute 2>/dev/null | fzf --reverse --border --prompt 'chezmoi> ')
[ -z "\$result" ] && rm -f "$tmp" && exit
source_file=\$(chezmoi source-path "\$result" 2>/dev/null) || {
    msg=\$(printf '%s' "unable to resolve source path for \$result" | sed "s/'/''/g")
    printf "evaluate-commands -client '$client' 'fail ''%s'''\n" "\$msg" | kak -p '$session'
    rm -f "$tmp"
    exit 1
}
kak_path=\$(printf '%s' "\$source_file" | sed "s/'/''/g")
printf "evaluate-commands -client '$client' 'edit -existing ''%s'''\n" "\$kak_path" | kak -p '$session'
rm -f "$tmp"
SHELL

        chmod +x "$tmp"
        kak_tmp=$(printf '%s' "$tmp" | sed "s/'/''/g")
        printf "tmux-terminal-vertical sh '%s'\n" "$kak_tmp"
    }
}

define-command \
    -docstring 'apply the current managed file to its destination path' \
    chezmoi-apply-current %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        kakline() { printf '%s' "$1" | tr '\n' ' ' | sed "s/'/''/g"; }

        resolve_target() {
            if [ -z "$kak_buffile" ]; then
                printf '%s\n' "current buffer is not a file"
                return 1
            fi

            source_root=$kak_opt_chezmoi_source_root
            if [ -n "$source_root" ]; then
                case "$kak_buffile" in
                    "$source_root"/*)
                        target=$(chezmoi target-path "$kak_buffile" 2>/dev/null) || {
                            printf '%s\n' "current source buffer is not managed by chezmoi"
                            return 1
                        }
                        source_file=$(chezmoi source-path "$target" 2>/dev/null) || {
                            printf '%s\n' "current source buffer is not managed by chezmoi"
                            return 1
                        }
                        [ "$source_file" = "$kak_buffile" ] || {
                            printf '%s\n' "current source buffer is not managed by chezmoi"
                            return 1
                        }
                        printf '%s\n' "$target"
                        return 0
                        ;;
                esac
            fi

            target="$kak_buffile"
            chezmoi source-path "$target" >/dev/null 2>&1 || {
                printf '%s\n' "current file is not managed by chezmoi"
                return 1
            }
            printf '%s\n' "$target"
            return 0
        }

        if [ "$kak_modified" = "true" ]; then
            printf "fail %s\n" "$(kakquote "write the buffer before applying with chezmoi")"
            exit
        fi

        target=$(resolve_target) || {
            printf "fail %s\n" "$(kakquote "$target")"
            exit
        }

        output=$(chezmoi apply --no-tty "$target" 2>&1)
        status=$?
        if [ $status -ne 0 ]; then
            printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
            exit
        fi

        if [ -n "$output" ]; then
            printf "echo -markup '{Information}%s'\n" "$(kakline "$output")"
        else
            printf "echo -markup '{Information}chezmoi applied %s'\n" "$(printf '%s' "$target" | sed "s/'/''/g")"
        fi
    }
}

define-command \
    -docstring 'add the current file to chezmoi, replacing source state if already managed' \
    chezmoi-add-current %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        kakline() { printf '%s' "$1" | tr '\n' ' ' | sed "s/'/''/g"; }

        resolve_add_target() {
            if [ -z "$kak_buffile" ]; then
                printf '%s\n' "current buffer is not a file"
                return 1
            fi

            source_root=$kak_opt_chezmoi_source_root
            if [ -n "$source_root" ]; then
                case "$kak_buffile" in
                    "$source_root"/*)
                        target=$(chezmoi target-path "$kak_buffile" 2>/dev/null) || {
                            printf '%s\n' "current source buffer cannot be mapped to a chezmoi target"
                            return 1
                        }
                        source_file=$(chezmoi source-path "$target" 2>/dev/null) || {
                            printf '%s\n' "current source buffer is not a managed chezmoi file"
                            return 1
                        }
                        [ "$source_file" = "$kak_buffile" ] || {
                            printf '%s\n' "current source buffer is not a managed chezmoi file"
                            return 1
                        }
                        printf '%s\n' "$target"
                        return 0
                        ;;
                esac
            fi

            printf '%s\n' "$kak_buffile"
            return 0
        }

        if [ "$kak_modified" = "true" ]; then
            printf "fail %s\n" "$(kakquote "write the buffer before adding it to chezmoi")"
            exit
        fi

        target=$(resolve_add_target) || {
            printf "fail %s\n" "$(kakquote "$target")"
            exit
        }

        output=$(chezmoi add "$target" 2>&1)
        status=$?
        if [ $status -ne 0 ]; then
            printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
            exit
        fi

        if [ -n "$output" ]; then
            printf "echo -markup '{Information}%s'\n" "$(kakline "$output")"
        else
            printf "echo -markup '{Information}chezmoi added %s'\n" "$(printf '%s' "$target" | sed "s/'/''/g")"
        fi
        printf "chezmoi-buffer-sync-state\n"
    }
}

define-command \
    -docstring 'remove the current managed file from chezmoi source state' \
    chezmoi-forget-current %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        kakline() { printf '%s' "$1" | tr '\n' ' ' | sed "s/'/''/g"; }

        resolve_target() {
            if [ -z "$kak_buffile" ]; then
                printf '%s\n' "current buffer is not a file"
                return 1
            fi

            source_root=$kak_opt_chezmoi_source_root
            if [ -n "$source_root" ]; then
                case "$kak_buffile" in
                    "$source_root"/*)
                        target=$(chezmoi target-path "$kak_buffile" 2>/dev/null) || {
                            printf '%s\n' "current source buffer is not managed by chezmoi"
                            return 1
                        }
                        source_file=$(chezmoi source-path "$target" 2>/dev/null) || {
                            printf '%s\n' "current source buffer is not managed by chezmoi"
                            return 1
                        }
                        [ "$source_file" = "$kak_buffile" ] || {
                            printf '%s\n' "current source buffer is not managed by chezmoi"
                            return 1
                        }
                        printf '%s\n' "$target"
                        return 0
                        ;;
                esac
            fi

            target="$kak_buffile"
            chezmoi source-path "$target" >/dev/null 2>&1 || {
                printf '%s\n' "current file is not managed by chezmoi"
                return 1
            }
            printf '%s\n' "$target"
            return 0
        }

        if [ "$kak_modified" = "true" ]; then
            printf "fail %s\n" "$(kakquote "write the buffer before removing it from chezmoi")"
            exit
        fi

        target=$(resolve_target) || {
            printf "fail %s\n" "$(kakquote "$target")"
            exit
        }

        output=$(chezmoi forget --force --no-tty "$target" 2>&1)
        status=$?
        if [ $status -ne 0 ]; then
            printf "fail %s\n" "$(kakquote "$(printf '%s' "$output" | tr '\n' ' ')")"
            exit
        fi

        if [ -n "$output" ]; then
            printf "echo -markup '{Information}%s'\n" "$(kakline "$output")"
        else
            printf "echo -markup '{Information}chezmoi forgot %s'\n" "$(printf '%s' "$target" | sed "s/'/''/g")"
        fi
        printf "chezmoi-buffer-sync-state\n"
    }
}

define-command \
    -docstring 'apply the full chezmoi target state' \
    chezmoi-apply-all %{
    evaluate-commands %sh{
        source_root="$kak_opt_chezmoi_source_root"
        tmp=$(mktemp /tmp/kak-chezmoi-apply-all-XXXXXX)

        cat > "$tmp" << SHELL
#!/bin/sh
cd "$source_root" || exit 1
chezmoi apply --no-tty
status=\$?
printf '\nPress enter to close...'
read dummy
rm -f "$tmp"
exit \$status
SHELL

        chmod +x "$tmp"
        kak_tmp=$(printf '%s' "$tmp" | sed "s/'/''/g")
        printf "tmux-terminal-vertical sh '%s'\n" "$kak_tmp"
    }
}

define-command \
    -docstring 'show chezmoi status for the current managed file' \
    chezmoi-status-current %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        resolve_target() {
            if [ -z "$kak_buffile" ]; then
                printf '%s\n' "current buffer is not a file"
                return 1
            fi

            source_root=$kak_opt_chezmoi_source_root
            if [ -n "$source_root" ]; then
                case "$kak_buffile" in
                    "$source_root"/*)
                        target=$(chezmoi target-path "$kak_buffile" 2>/dev/null) || {
                            printf '%s\n' "current source buffer is not managed by chezmoi"
                            return 1
                        }
                        source_file=$(chezmoi source-path "$target" 2>/dev/null) || {
                            printf '%s\n' "current source buffer is not managed by chezmoi"
                            return 1
                        }
                        [ "$source_file" = "$kak_buffile" ] || {
                            printf '%s\n' "current source buffer is not managed by chezmoi"
                            return 1
                        }
                        printf '%s\n' "$target"
                        return 0
                        ;;
                esac
            fi

            target="$kak_buffile"
            chezmoi source-path "$target" >/dev/null 2>&1 || {
                printf '%s\n' "current file is not managed by chezmoi"
                return 1
            }
            printf '%s\n' "$target"
            return 0
        }

        target=$(resolve_target) || {
            printf "fail %s\n" "$(kakquote "$target")"
            exit
        }

        source_root="$kak_opt_chezmoi_source_root"
        tmp=$(mktemp /tmp/kak-chezmoi-status-XXXXXX)

        cat > "$tmp" << SHELL
#!/bin/sh
cd "$source_root" || exit 1
chezmoi status "$target"
status=\$?
printf '\nPress enter to close...'
read dummy
rm -f "$tmp"
exit \$status
SHELL

        chmod +x "$tmp"
        kak_tmp=$(printf '%s' "$tmp" | sed "s/'/''/g")
        printf "tmux-terminal-vertical sh '%s'\n" "$kak_tmp"
    }
}

define-command \
    -docstring 'show chezmoi diff for the current managed file' \
    chezmoi-diff-current %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        resolve_target() {
            if [ -z "$kak_buffile" ]; then
                printf '%s\n' "current buffer is not a file"
                return 1
            fi

            source_root=$kak_opt_chezmoi_source_root
            if [ -n "$source_root" ]; then
                case "$kak_buffile" in
                    "$source_root"/*)
                        target=$(chezmoi target-path "$kak_buffile" 2>/dev/null) || {
                            printf '%s\n' "current source buffer is not managed by chezmoi"
                            return 1
                        }
                        source_file=$(chezmoi source-path "$target" 2>/dev/null) || {
                            printf '%s\n' "current source buffer is not managed by chezmoi"
                            return 1
                        }
                        [ "$source_file" = "$kak_buffile" ] || {
                            printf '%s\n' "current source buffer is not managed by chezmoi"
                            return 1
                        }
                        printf '%s\n' "$target"
                        return 0
                        ;;
                esac
            fi

            target="$kak_buffile"
            chezmoi source-path "$target" >/dev/null 2>&1 || {
                printf '%s\n' "current file is not managed by chezmoi"
                return 1
            }
            printf '%s\n' "$target"
            return 0
        }

        target=$(resolve_target) || {
            printf "fail %s\n" "$(kakquote "$target")"
            exit
        }

        source_root="$kak_opt_chezmoi_source_root"
        tmp=$(mktemp /tmp/kak-chezmoi-diff-XXXXXX)

        cat > "$tmp" << SHELL
#!/bin/sh
cd "$source_root" || exit 1
chezmoi diff "$target"
status=\$?
printf '\nPress enter to close...'
read dummy
rm -f "$tmp"
exit \$status
SHELL

        chmod +x "$tmp"
        kak_tmp=$(printf '%s' "$tmp" | sed "s/'/''/g")
        printf "tmux-terminal-vertical sh '%s'\n" "$kak_tmp"
    }
}

define-command \
    -docstring 'show chezmoi diff for all managed files' \
    chezmoi-diff-all %{
    evaluate-commands %sh{
        source_root="$kak_opt_chezmoi_source_root"
        tmp=$(mktemp /tmp/kak-chezmoi-diff-all-XXXXXX)

        cat > "$tmp" << SHELL
#!/bin/sh
cd "$source_root" || exit 1
chezmoi diff
status=\$?
printf '\nPress enter to close...'
read dummy
rm -f "$tmp"
exit \$status
SHELL

        chmod +x "$tmp"
        kak_tmp=$(printf '%s' "$tmp" | sed "s/'/''/g")
        printf "tmux-terminal-vertical sh '%s'\n" "$kak_tmp"
    }
}

define-command \
    -docstring 'show chezmoi git status' \
    chezmoi-git-status %{
    evaluate-commands %sh{
        source_root="$kak_opt_chezmoi_source_root"
        tmp=$(mktemp /tmp/kak-chezmoi-git-status-XXXXXX)

        cat > "$tmp" << SHELL
#!/bin/sh
cd "$source_root" || exit 1
chezmoi git status
status=\$?
printf '\nPress enter to close...'
read dummy
rm -f "$tmp"
exit \$status
SHELL

        chmod +x "$tmp"
        kak_tmp=$(printf '%s' "$tmp" | sed "s/'/''/g")
        printf "tmux-terminal-vertical sh '%s'\n" "$kak_tmp"
    }
}

define-command \
    -params 1.. \
    -docstring 'run an arbitrary chezmoi subcommand in a tmux pane' \
    chezmoi-run %{
    evaluate-commands %sh{
        source_root="$kak_opt_chezmoi_source_root"
        tmp=$(mktemp /tmp/kak-chezmoi-run-XXXXXX)

        cat > "$tmp" << SHELL
#!/bin/sh
cd "$source_root" || exit 1
chezmoi "\$@"
status=\$?
printf '\nPress enter to close...'
read dummy
rm -f "$tmp"
exit \$status
SHELL

        chmod +x "$tmp"
        kak_tmp=$(printf '%s' "$tmp" | sed "s/'/''/g")
        printf "tmux-terminal-vertical sh '%s' %s\n" "$kak_tmp" "%arg{@}"
    }
}

hook global BufOpenFile .* %{ chezmoi-buffer-sync-state }
hook global BufNewFile  .* %{ chezmoi-buffer-sync-state }

try %{ declare-user-mode chezmoi }
map global chezmoi f ':chezmoi-find<ret>'          -docstring 'find managed file'
map global chezmoi M ':chezmoi-add-current<ret>'   -docstring 'manage current file'
map global chezmoi X ':chezmoi-forget-current<ret>' -docstring 'forget current file'
# map global chezmoi a ':chezmoi-apply-current<ret>' -docstring 'apply current file'
map global chezmoi A ':chezmoi-apply-all<ret>'     -docstring 'apply all'
map global chezmoi s ':chezmoi-status-current<ret>' -docstring 'status current'
map global chezmoi d ':chezmoi-diff-current<ret>'   -docstring 'diff current'
map global chezmoi D ':chezmoi-diff-all<ret>'       -docstring 'diff all'
map global chezmoi g ':chezmoi-git-status<ret>'     -docstring 'git status'
map global chezmoi ! ':chezmoi-run '                -docstring 'run chezmoi command'
