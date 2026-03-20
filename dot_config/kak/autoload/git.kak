try %{ declare-option -hidden str git_timemachine_origin_buffer '' }
try %{ declare-option -hidden str git_timemachine_origin_cursor '' }
try %{ declare-option -hidden str git_timemachine_origin_file '' }
try %{ declare-option -hidden str git_timemachine_origin_filetype '' }
try %{ declare-option -hidden str git_timemachine_preview_buffer '' }
try %{ declare-option -hidden str git_timemachine_return_buffer '' }
try %{ declare-option -hidden str git_timemachine_return_cursor '' }

define-command -hidden git-timemachine-reset %{
    set-option current git_timemachine_origin_buffer ''
    set-option current git_timemachine_origin_cursor ''
    set-option current git_timemachine_origin_file ''
    set-option current git_timemachine_origin_filetype ''
    set-option current git_timemachine_preview_buffer ''
}

define-command -hidden -params 2 git-timemachine-preview %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        kakline() { printf '%s' "$1" | tr '\n' ' ' | sed "s/'/''/g"; }

        commit=$1
        path_at_commit=$2
        origin_file=$kak_opt_git_timemachine_origin_file
        origin_buffer=$kak_opt_git_timemachine_origin_buffer
        origin_cursor=$kak_opt_git_timemachine_origin_cursor
        origin_filetype=$kak_opt_git_timemachine_origin_filetype
        preview_buffer=$kak_opt_git_timemachine_preview_buffer

        [ -n "$commit" ] || {
            printf "fail %s\n" "$(kakquote "git-timemachine preview requires a commit id")"
            exit
        }
        [ -n "$path_at_commit" ] || {
            printf "fail %s\n" "$(kakquote "git-timemachine preview requires a file path")"
            exit
        }
        [ -n "$origin_file" ] || {
            printf "fail %s\n" "$(kakquote "git-timemachine has no active source file")"
            exit
        }

        repo_dir=${origin_file%/*}
        repo_root=$(git -C "$repo_dir" rev-parse --show-toplevel 2>/dev/null) || {
            printf "fail %s\n" "$(kakquote "unable to resolve the git repository for $origin_file")"
            exit
        }

        meta=$(git -C "$repo_root" show -s --date=short --format='%h%x09%ad%x09%an%x09%s' "$commit" 2>/dev/null) || {
            printf "fail %s\n" "$(kakquote "unable to read commit metadata for $commit")"
            exit
        }

        short_hash=$(printf '%s' "$meta" | cut -f1)
        commit_date=$(printf '%s' "$meta" | cut -f2)
        commit_author=$(printf '%s' "$meta" | cut -f3)
        commit_subject=$(printf '%s' "$meta" | cut -f4-)

        tmp=$(mktemp /tmp/kak-git-timemachine-XXXXXX)
        if ! git -C "$repo_root" show "$commit:$path_at_commit" >"$tmp" 2>/dev/null; then
            rm -f "$tmp"
            printf "fail %s\n" "$(kakquote "unable to load $path_at_commit at $short_hash")"
            exit
        fi

        if [ -n "$preview_buffer" ]; then
            printf "try %%{ buffer %s; edit! -existing %s } catch %%{ edit -existing %s }\n" \
                "$(kakquote "$preview_buffer")" "$(kakquote "$tmp")" \
                "$(kakquote "$tmp")"
        else
            printf "edit -existing %s\n" "$(kakquote "$tmp")"
        fi
        if [ -n "$preview_buffer" ] && [ "$preview_buffer" != "$tmp" ]; then
            printf "nop %%sh{ rm -f %s }\n" "$(kakquote "$preview_buffer")"
        fi
        if [ -n "$origin_filetype" ]; then
            printf "set-option buffer filetype %s\n" "$(kakquote "$origin_filetype")"
        fi
        printf "set-option buffer readonly true\n"
        printf "set-option buffer git_timemachine_return_buffer %s\n" "$(kakquote "$origin_buffer")"
        printf "set-option buffer git_timemachine_return_cursor %s\n" "$(kakquote "$origin_cursor")"
        printf "map buffer normal q ':git-timemachine-close<ret>' -docstring %s\n" \
            "$(kakquote "close timemachine revision")"
        printf "set-option current git_timemachine_preview_buffer %s\n" "$(kakquote "$tmp")"
        printf "echo -markup '{Information}%s'\n" \
            "$(kakline "$short_hash $commit_date $commit_author: $commit_subject")"
    }
}

define-command -hidden -params 2 git-timemachine-accept %{
    git-timemachine-preview %arg{1} %arg{2}
    set-option current git_timemachine_origin_buffer ''
    set-option current git_timemachine_origin_cursor ''
    set-option current git_timemachine_origin_file ''
    set-option current git_timemachine_origin_filetype ''
    set-option current git_timemachine_preview_buffer ''
}

define-command -hidden git-timemachine-cancel %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        origin_buffer=$kak_opt_git_timemachine_origin_buffer
        origin_cursor=$kak_opt_git_timemachine_origin_cursor
        preview_buffer=$kak_opt_git_timemachine_preview_buffer

        if [ -n "$origin_buffer" ]; then
            printf "try %%{ buffer %s }\n" "$(kakquote "$origin_buffer")"
        fi
        if [ -n "$origin_cursor" ]; then
            printf "try %%{ select %s,%s }\n" "$origin_cursor" "$origin_cursor"
        fi
        if [ -n "$preview_buffer" ]; then
            printf "try %%{ delete-buffer! %s }\n" "$(kakquote "$preview_buffer")"
            printf "nop %%sh{ rm -f %s }\n" "$(kakquote "$preview_buffer")"
        fi
        printf "git-timemachine-reset\n"
    }
}

define-command -hidden git-timemachine-close %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        origin_buffer=$kak_opt_git_timemachine_return_buffer
        origin_cursor=$kak_opt_git_timemachine_return_cursor
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

define-command -docstring 'browse file history with an fzf-driven git timemachine' git-timemachine %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        session=$kak_session
        client=$kak_client
        buffile=$kak_buffile
        bufname=$kak_bufname
        cursor="${kak_cursor_line}.${kak_cursor_column}"
        filetype=$kak_opt_filetype

        [ -n "$TMUX" ] || {
            printf "fail %s\n" "$(kakquote "git-timemachine requires Kakoune to run inside tmux")"
            exit
        }

        command -v git >/dev/null 2>&1 || {
            printf "fail %s\n" "$(kakquote "git command not found in PATH")"
            exit
        }

        command -v fzf >/dev/null 2>&1 || {
            printf "fail %s\n" "$(kakquote "fzf command not found in PATH")"
            exit
        }

        [ -n "$buffile" ] || {
            printf "fail %s\n" "$(kakquote "git-timemachine only works for file-backed buffers")"
            exit
        }

        repo_dir=${buffile%/*}
        repo_root=$(git -C "$repo_dir" rev-parse --show-toplevel 2>/dev/null) || {
            printf "fail %s\n" "$(kakquote "current buffer is not inside a git repository")"
            exit
        }

        relpath=$(git -C "$repo_root" ls-files --full-name -- "$buffile" 2>/dev/null)
        [ -n "$relpath" ] || {
            printf "fail %s\n" "$(kakquote "current file is not tracked by git")"
            exit
        }

        git -C "$repo_root" log --follow -n 1 --format='%H' -- "$relpath" >/dev/null 2>&1 || {
            printf "fail %s\n" "$(kakquote "no git history found for $relpath")"
            exit
        }

        tmp=$(mktemp /tmp/kak-git-timemachine-XXXXXX)

        session_q=$(printf '%s' "$session" | sed "s/'/'\\\\''/g")
        client_q=$(printf '%s' "$client" | sed "s/'/'\\\\''/g")
        root_q=$(printf '%s' "$repo_root" | sed "s/'/'\\\\''/g")
        relpath_q=$(printf '%s' "$relpath" | sed "s/'/'\\\\''/g")
        kak_bin=$(command -v kak 2>/dev/null) || {
            printf "fail %s\n" "$(kakquote "kak executable not found in PATH")"
            exit
        }
        kak_bin_q=$(printf '%s' "$kak_bin" | sed "s/'/'\\\\''/g")

        cat > "$tmp" << SHELL
#!/bin/sh
SESSION='$session_q'
CLIENT='$client_q'
ROOT='$root_q'
RELPATH='$relpath_q'
KAK_BIN='$kak_bin_q'
SEP=$(printf '\037')

run_for_client() {
    cmd=\$1
    shift
    payload="evaluate-commands -client '\$CLIENT' %{ \$cmd"
    for arg in "\$@"; do
        escaped=\$(printf '%s' "\$arg" | sed "s/'/''/g")
        payload="\$payload '\$escaped'"
    done
    payload="\$payload }"
    printf "%s\n" "\$payload" | "\$KAK_BIN" -p "\$SESSION"
}

preview_commit() {
    run_for_client git-timemachine-preview "\$1" "\$2"
}

accept_commit() {
    run_for_client git-timemachine-accept "\$1" "\$2"
}

cancel_timemachine() {
    run_for_client git-timemachine-cancel
}

build_commits() {
    git -C "\$ROOT" log --follow --date=short --format='__TM__%H%x09%h%x09%ad%x09%an%x09%s' \
        --name-status --find-renames -- "\$RELPATH" |
    awk -F "\t" -v current_path="\$RELPATH" -v sep="\$SEP" '
        function flush_commit() {
            if (!seen) {
                return
            }
            display = commit_subject "  [" commit_short " " commit_date " " commit_author "]"
            printf "%s%s%s%s%s\n", display, sep, commit_full, sep, current_path
            if (rename_old != "" && rename_new == current_path) {
                current_path = rename_old
            }
        }
        /^__TM__/ {
            flush_commit()
            meta = substr(\$0, 7)
            split(meta, fields, "\t")
            commit_full = fields[1]
            commit_short = fields[2]
            commit_date = fields[3]
            commit_author = fields[4]
            commit_subject = fields[5]
            rename_old = ""
            rename_new = ""
            seen = 1
            next
        }
        NF == 0 { next }
        \$1 ~ /^R[0-9]*$/ {
            rename_old = \$2
            rename_new = \$3
            next
        }
        END {
            flush_commit()
        }
    '
}

case "\${1-}" in
    --preview)
        shift
        preview_commit "\$1" "\$2"
        exit
        ;;
    --accept)
        shift
        accept_commit "\$1" "\$2"
        rm -f "\$0"
        exit
        ;;
    --cancel)
        cancel_timemachine
        rm -f "\$0"
        exit
        ;;
esac

cd "\$ROOT" || exit 1
commits=\$(build_commits)

[ -n "\$commits" ] || {
    cancel_timemachine
    rm -f "\$0"
    exit 1
}

result=\$(printf '%s\n' "\$commits" | \
    fzf --reverse --border --delimiter "\$SEP" --with-nth=1 \
        --prompt 'timemachine> ' \
        --header 'move to preview, <ret> keep revision, <esc> restore file' \
        --bind "start:execute-silent(\$0 --preview {2} {3}),focus:execute-silent(\$0 --preview {2} {3})")
status=\$?

if [ \$status -ne 0 ] || [ -z "\$result" ]; then
    "\$0" --cancel
    exit
fi

commit=\$(printf '%s' "\$result" | cut -d "\$SEP" -f2)
path_at_commit=\$(printf '%s' "\$result" | cut -d "\$SEP" -f3)
"\$0" --accept "\$commit" "\$path_at_commit"
SHELL

        chmod +x "$tmp"

        printf "git-timemachine-reset\n"
        printf "set-option current git_timemachine_origin_buffer %s\n" "$(kakquote "$bufname")"
        printf "set-option current git_timemachine_origin_cursor %s\n" "$(kakquote "$cursor")"
        printf "set-option current git_timemachine_origin_file %s\n" "$(kakquote "$buffile")"
        printf "set-option current git_timemachine_origin_filetype %s\n" "$(kakquote "$filetype")"
        printf "tmux-terminal-vertical sh %s\n" "$(kakquote "$tmp")"
    }
}

define-command -hidden git-buffer-sync-state %{
    evaluate-commands %sh{
        buffile=$kak_buffile

        printf "remove-hooks buffer git-auto-show-diff\n"

        [ -n "$buffile" ] || exit

        repo_dir=${buffile%/*}
        repo_root=$(git -C "$repo_dir" rev-parse --show-toplevel 2>/dev/null) || exit
        relpath=$(git -C "$repo_root" ls-files --full-name -- "$buffile" 2>/dev/null)
        [ -n "$relpath" ] || exit

        printf "git show-diff\n"
        printf "hook -group git-auto-show-diff buffer BufWritePost .* %%{ git show-diff }\n"
    }
}

declare-user-mode git

map global git a ':git add<ret>'             -docstring 'add current file'
map global git A ':git apply<ret>'           -docstring 'apply git patch'
map global git b ':git blame<ret>'           -docstring 'toggle blame'
map global git j ':git blame-jump<ret>'      -docstring 'jump to blamed commit'
map global git c ':git checkout<ret>'        -docstring 'checkout'
map global git C ':git commit<ret>'          -docstring 'commit'
map global git d ':git diff<ret>'            -docstring 'diff'
map global git D ':git show-diff<ret>'       -docstring 'show diff markers'
map global git e ':git edit<ret>'            -docstring 'edit tracked file'
map global git g ':git grep<ret>'            -docstring 'git grep'
map global git h ':git hide-diff<ret>'       -docstring 'hide diff markers'
map global git i ':git init<ret>'            -docstring 'init repository'
map global git l ':git log<ret>'             -docstring 'log'
map global git '[' ':git prev-hunk<ret>'     -docstring 'previous hunk'
map global git ']' ':git next-hunk<ret>'     -docstring 'next hunk'
map global git r ':git reset<ret>'           -docstring 'reset'
map global git R ':git rm<ret>'              -docstring 'remove current file'
map global git s ':git status<ret>'          -docstring 'status'
map global git S ':git show<ret>'            -docstring 'show object'
map global git t ':git show-branch<ret>'     -docstring 'show branches'
map global git T ':git-timemachine<ret>'     -docstring 'browse file history'
map global git u ':git update-diff<ret>'     -docstring 'refresh diff markers'

hook global WinDisplay .* %{ git-buffer-sync-state }
