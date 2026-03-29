try %{ declare-option -hidden str gh_review_patch_file '' }
try %{ declare-option -hidden str gh_review_picker_root '' }
try %{ declare-option -hidden str gh_review_manifest_file '' }
try %{ declare-option -hidden str gh_review_repo_root '' }
try %{ declare-option -hidden str gh_review_pr_number '' }
try %{ declare-option -hidden bool gh_review_buffer false }
try %{ declare-option -hidden str gh_review_temp_file '' }
try %{ declare-option -hidden str gh_review_section_path '' }
try %{ declare-option -hidden str gh_review_return_buffer '' }
try %{ declare-option -hidden str gh_review_return_cursor '' }

define-command -hidden gh-review-close-buffer %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        return_buffer=$kak_opt_gh_review_return_buffer
        return_cursor=$kak_opt_gh_review_return_cursor
        temp_file=$kak_opt_gh_review_temp_file
        current_buffer=$kak_bufname

        if [ -n "$return_buffer" ] && [ "$return_buffer" != "$current_buffer" ]; then
            printf "try %%{ buffer %s }\n" "$(kakquote "$return_buffer")"
            if [ -n "$return_cursor" ]; then
                printf "try %%{ select %s,%s }\n" "$return_cursor" "$return_cursor"
            fi
        fi

        if [ -n "$temp_file" ]; then
            printf "nop %%sh{ rm -f %s }\n" "$(kakquote "$temp_file")"
            if [ "$kak_opt_gh_review_patch_file" = "$temp_file" ]; then
                printf "set-option global gh_review_patch_file ''\n"
            fi
        fi

        printf "delete-buffer! %s\n" "$(kakquote "$current_buffer")"
    }
}

define-command -hidden gh-review-refresh-state %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        shellquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

        resolve_repo_root() {
            if [ -n "$kak_opt_gh_review_repo_root" ] && \
                git -C "$kak_opt_gh_review_repo_root" rev-parse --show-toplevel >/dev/null 2>&1; then
                printf '%s\n' "$kak_opt_gh_review_repo_root"
                return 0
            fi

            if [ -n "$kak_buffile" ] && [ -e "$kak_buffile" ]; then
                repo_dir=${kak_buffile%/*}
                git -C "$repo_dir" rev-parse --show-toplevel 2>/dev/null && return 0
            fi

            git rev-parse --show-toplevel 2>/dev/null
        }

        resolve_review_pr_number() {
            repo_root=$1
            branch_name=$(git -C "$repo_root" branch --show-current 2>/dev/null || true)
            case "$branch_name" in
                review/pr-*)
                    pr_number=${branch_name#review/pr-}
                    case "$pr_number" in
                        ''|*[!0-9]*)
                            ;;
                        *)
                            printf '%s\n' "$pr_number"
                            return 0
                            ;;
                    esac
                    ;;
            esac

            worktree_name=${repo_root##*/}
            case "$worktree_name" in
                gh__*__*__PR*__*__*)
                    worktree_rest=${worktree_name#gh__}
                    worktree_rest=${worktree_rest#*__}
                    worktree_rest=${worktree_rest#*__}
                    pr_field=${worktree_rest%%__*}
                    pr_number=${pr_field#PR}
                    case "$pr_number" in
                        ''|*[!0-9]*)
                            ;;
                        *)
                            printf '%s\n' "$pr_number"
                            return 0
                            ;;
                    esac
                    ;;
                *.PR*)
                    pr_number=${worktree_name##*.PR}
                    case "$pr_number" in
                        ''|*[!0-9]*)
                            ;;
                        *)
                            printf '%s\n' "$pr_number"
                            return 0
                            ;;
                    esac
                    ;;
            esac

            return 1
        }

        command -v gh >/dev/null 2>&1 || {
            printf "fail %s\n" "$(kakquote "gh command not found in PATH")"
            exit
        }

        command -v git >/dev/null 2>&1 || {
            printf "fail %s\n" "$(kakquote "git command not found in PATH")"
            exit
        }

        repo_root=$(resolve_repo_root) || {
            printf "fail %s\n" "$(kakquote "unable to resolve a git repository for the current review context")"
            exit
        }
        review_pr=$(resolve_review_pr_number "$repo_root" 2>/dev/null || true)

        patch_file=$kak_opt_gh_review_patch_file
        [ -n "$patch_file" ] || patch_file=$(mktemp "${TMPDIR:-/tmp}/kak-gh-review.XXXXXX")

        manifest_file=$(mktemp "${TMPDIR:-/tmp}/kak-gh-review-files.XXXXXX.tsv")
        picker_root=$(mktemp -d "${TMPDIR:-/tmp}/kak-gh-review-tree.XXXXXX")
        patch_tmp=$(mktemp "${TMPDIR:-/tmp}/kak-gh-review-fetch.XXXXXX")
        list_tmp=$(mktemp "${TMPDIR:-/tmp}/kak-gh-review-files.XXXXXX.list")
        err_tmp=$(mktemp "${TMPDIR:-/tmp}/kak-gh-review-error.XXXXXX")

        cleanup() {
            rm -f "$patch_tmp" "$list_tmp" "$err_tmp"
        }

        if ! (
            cd "$repo_root" || exit 1
            if [ -n "$review_pr" ]; then
                gh pr diff "$review_pr" --patch --color=never >"$patch_tmp"
            else
                gh pr diff --patch --color=never >"$patch_tmp"
            fi
        ) 2>"$err_tmp"; then
            message=$(tr '\n' ' ' <"$err_tmp")
            [ -n "$message" ] || message='unable to fetch the current pull request diff'
            cleanup
            rm -f "$manifest_file"
            rm -rf "$picker_root"
            printf "fail %s\n" "$(kakquote "$message")"
            exit
        fi

        if ! (
            cd "$repo_root" || exit 1
            if [ -n "$review_pr" ]; then
                gh pr diff "$review_pr" --name-only --color=never >"$list_tmp"
            else
                gh pr diff --name-only --color=never >"$list_tmp"
            fi
        ) 2>"$err_tmp"; then
            message=$(tr '\n' ' ' <"$err_tmp")
            [ -n "$message" ] || message='unable to list changed pull request files'
            cleanup
            rm -f "$manifest_file"
            rm -rf "$picker_root"
            printf "fail %s\n" "$(kakquote "$message")"
            exit
        fi

        if [ ! -s "$patch_tmp" ]; then
            cleanup
            rm -f "$manifest_file"
            rm -rf "$picker_root"
            printf "fail %s\n" "$(kakquote "GitHub reports no diff for the current pull request")"
            exit
        fi

        mv "$patch_tmp" "$patch_file"
        : >"$manifest_file"

        while IFS= read -r relpath; do
            [ -n "$relpath" ] || continue
            stub="$picker_root/$relpath"
            mkdir -p "$(dirname "$stub")"
            : >"$stub"
            printf '%s\t%s\n' "$stub" "$relpath" >>"$manifest_file"
        done <"$list_tmp"

        cleanup

        if [ ! -s "$manifest_file" ]; then
            rm -f "$manifest_file"
            rm -rf "$picker_root"
            printf "fail %s\n" "$(kakquote "GitHub reports no changed files for the current pull request")"
            exit
        fi

        if [ -n "$kak_opt_gh_review_manifest_file" ] && [ "$kak_opt_gh_review_manifest_file" != "$manifest_file" ]; then
            printf "nop %%sh{ rm -f %s }\n" "$(kakquote "$kak_opt_gh_review_manifest_file")"
        fi
        if [ -n "$kak_opt_gh_review_picker_root" ] && [ "$kak_opt_gh_review_picker_root" != "$picker_root" ]; then
            printf "nop %%sh{ rm -rf %s }\n" "$(kakquote "$kak_opt_gh_review_picker_root")"
        fi

        printf "set-option global gh_review_patch_file %s\n" "$(kakquote "$patch_file")"
        printf "set-option global gh_review_manifest_file %s\n" "$(kakquote "$manifest_file")"
        printf "set-option global gh_review_picker_root %s\n" "$(kakquote "$picker_root")"
        printf "set-option global gh_review_repo_root %s\n" "$(kakquote "$repo_root")"
        printf "set-option global gh_review_pr_number %s\n" "$(kakquote "$review_pr")"
    }
}

define-command -hidden gh-review-ensure-state %{
    evaluate-commands %sh{
        if [ -n "$kak_opt_gh_review_patch_file" ] && [ -f "$kak_opt_gh_review_patch_file" ] && \
            [ -n "$kak_opt_gh_review_manifest_file" ] && [ -f "$kak_opt_gh_review_manifest_file" ] && \
            [ -n "$kak_opt_gh_review_picker_root" ] && [ -d "$kak_opt_gh_review_picker_root" ]; then
            exit
        fi

        printf "gh-review-refresh-state\n"
    }
}

define-command -hidden -params 2 gh-review-open-buffer %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        temp_file=$1
        section_path=$2
        origin_buffer=$kak_bufname
        origin_cursor="${kak_cursor_line}.${kak_cursor_column}"
        repo_root=$kak_opt_gh_review_repo_root

        [ -f "$temp_file" ] || {
            printf "fail %s\n" "$(kakquote "review buffer file is missing: $temp_file")"
            exit
        }

        printf "edit! -existing %s\n" "$(kakquote "$temp_file")"
        printf "require-module diff\n"
        printf "set-option buffer filetype git-diff\n"
        printf "try %%{ add-highlighter window/git-diff-ref-diff ref diff }\n"
        printf "set-option buffer readonly true\n"
        printf "set-option buffer gh_review_buffer true\n"
        printf "set-option buffer gh_review_temp_file %s\n" "$(kakquote "$temp_file")"
        printf "set-option buffer gh_review_section_path %s\n" "$(kakquote "$section_path")"
        printf "set-option buffer gh_review_repo_root %s\n" "$(kakquote "$repo_root")"
        printf "set-option buffer gh_review_return_buffer %s\n" "$(kakquote "$origin_buffer")"
        printf "set-option buffer gh_review_return_cursor %s\n" "$(kakquote "$origin_cursor")"
        printf "map buffer normal q ':gh-review-close-buffer<ret>' -docstring %s\n" \
            "$(kakquote "close review buffer")"
        printf "map buffer normal o ':gh-diff-open-working-tree-file<ret>' -docstring %s\n" \
            "$(kakquote "open working tree file")"
        printf "map buffer normal '[' ':gh-prev-hunk<ret>' -docstring %s\n" \
            "$(kakquote "previous review hunk")"
        printf "map buffer normal ']' ':gh-next-hunk<ret>' -docstring %s\n" \
            "$(kakquote "next review hunk")"
    }
}

define-command -docstring 'refresh cached GitHub pull request review state' gh-pr-refresh %{
    gh-review-refresh-state
}

define-command -docstring 'open the current pull request diff in a review buffer' gh-pr-diff %{
    gh-review-refresh-state
    gh-review-open-buffer %opt{gh_review_patch_file} ''
}

define-command -params 1 -docstring 'open the diff for a changed pull request file' gh-pr-diff-file %{
    gh-review-ensure-state
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        target=$1
        patch_file=$kak_opt_gh_review_patch_file

        [ -n "$patch_file" ] && [ -f "$patch_file" ] || {
            printf "fail %s\n" "$(kakquote "no cached pull request diff is available")"
            exit
        }

        tmp=$(mktemp "${TMPDIR:-/tmp}/kak-gh-file.XXXXXX") || {
            printf "fail %s\n" "$(kakquote "unable to create a temporary file diff buffer")"
            exit
        }

        if ! awk -v target="$target" '
function reset_state() {
    block = ""
    old = ""
    new = ""
    path = ""
    matched = 0
}
function finalize_path() {
    if (path != "") {
        return
    }
    if (new != "" && new != "/dev/null") {
        path = new
        sub(/^b\//, "", path)
    } else if (old != "" && old != "/dev/null") {
        path = old
        sub(/^a\//, "", path)
    }
    if (path == target) {
        matched = 1
    }
}
function flush_block() {
    finalize_path()
    if (matched) {
        printf "%s", block
        printed = 1
    }
    reset_state()
}
/^diff --git / {
    if (block != "") {
        flush_block()
        if (printed) {
            exit
        }
    }
    block = $0 ORS
    next
}
{
    if (block == "") {
        next
    }
    block = block $0 ORS
    if ($0 ~ /^--- /) {
        old = substr($0, 5)
    } else if ($0 ~ /^\+\+\+ /) {
        new = substr($0, 5)
        finalize_path()
    }
}
END {
    if (block != "") {
        flush_block()
    }
}' "$patch_file" >"$tmp"; then
            rm -f "$tmp"
            printf "fail %s\n" "$(kakquote "unable to extract the diff for $target")"
            exit
        fi

        if [ ! -s "$tmp" ]; then
            rm -f "$tmp"
            printf "fail %s\n" "$(kakquote "the current pull request diff does not contain $target")"
            exit
        fi

        printf "gh-review-open-buffer %s %s\n" "$(kakquote "$tmp")" "$(kakquote "$target")"
    }
}

define-command -docstring 'browse changed pull request files with lf' gh-pr-files %{
    gh-review-ensure-state
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        resolve_review_section_path() {
            [ -n "$kak_buffile" ] && [ -f "$kak_buffile" ] || return 1
            awk -v target="$kak_cursor_line" '
NR > target { exit }
/^diff --git / {
    old = ""
    new = ""
    path = ""
    next
}
/^--- / {
    old = substr($0, 5)
    if (old == "/dev/null") {
        old = ""
    } else if (index(old, "a/") == 1) {
        old = substr(old, 3)
    }
    next
}
/^\+\+\+ / {
    new = substr($0, 5)
    if (new == "/dev/null") {
        new = ""
    } else if (index(new, "b/") == 1) {
        new = substr(new, 3)
    }
    path = (new != "" ? new : old)
}
END {
    if (path != "") {
        print path
    }
}' "$kak_buffile"
        }

        helper_path="${HOME}/.local/bin/kak-picker-gh-pr-files"
        [ -x "$helper_path" ] || {
            printf "fail %s\n" "$(kakquote "picker helper not found: $helper_path")"
            exit
        }

        [ -n "$kak_opt_gh_review_picker_root" ] && [ -d "$kak_opt_gh_review_picker_root" ] || {
            printf "fail %s\n" "$(kakquote "no changed-file picker state is available")"
            exit
        }
        [ -n "$kak_opt_gh_review_manifest_file" ] && [ -f "$kak_opt_gh_review_manifest_file" ] || {
            printf "fail %s\n" "$(kakquote "no changed-file manifest is available")"
            exit
        }

        tmp=$(mktemp "${TMPDIR:-/tmp}/kak-gh-picker.XXXXXX") || {
            printf "fail %s\n" "$(kakquote "unable to create a temporary picker launcher")"
            exit
        }

        session_q=$(printf '%s' "$kak_session" | sed "s/'/'\\\\''/g")
        client_q=$(printf '%s' "$kak_client" | sed "s/'/'\\\\''/g")
        root_q=$(printf '%s' "$kak_opt_gh_review_picker_root" | sed "s/'/'\\\\''/g")
        manifest_q=$(printf '%s' "$kak_opt_gh_review_manifest_file" | sed "s/'/'\\\\''/g")
        helper_q=$(printf '%s' "$helper_path" | sed "s/'/'\\\\''/g")
        cwd_q=$(printf '%s' "$PWD" | sed "s/'/'\\\\''/g")
        start_path=$kak_opt_gh_review_picker_root
        if [ -n "$kak_opt_gh_review_section_path" ]; then
            candidate=$kak_opt_gh_review_picker_root/$kak_opt_gh_review_section_path
            if [ -e "$candidate" ]; then
                start_path=$candidate
            fi
        elif [ "$kak_opt_gh_review_buffer" = "true" ]; then
            relpath=$(resolve_review_section_path 2>/dev/null || true)
            if [ -n "$relpath" ]; then
                candidate=$kak_opt_gh_review_picker_root/$relpath
                if [ -e "$candidate" ]; then
                    start_path=$candidate
                fi
            fi
        elif [ -n "$kak_buffile" ] && [ -n "$kak_opt_gh_review_repo_root" ]; then
            case "$kak_buffile" in
                "$kak_opt_gh_review_repo_root"/*)
                    relpath=${kak_buffile#"$kak_opt_gh_review_repo_root"/}
                    candidate=$kak_opt_gh_review_picker_root/$relpath
                    if [ -e "$candidate" ]; then
                        start_path=$candidate
                    fi
                    ;;
            esac
        fi
        start_q=$(printf '%s' "$start_path" | sed "s/'/'\\\\''/g")

        cat >"$tmp" << SHELL
#!/bin/sh
export KAK_PICKER_SESSION='$session_q'
export KAK_PICKER_CLIENT='$client_q'
export KAK_GH_PICKER_ROOT='$root_q'
export KAK_GH_PICKER_MANIFEST='$manifest_q'
export KAK_GH_PICKER_START='$start_q'
cd '$cwd_q' || exit 1
'$helper_q'
status=\$?
rm -f '$tmp'
exit "\$status"
SHELL

        chmod +x "$tmp"
        printf "tmux-terminal-vertical sh %s\n" "$(kakquote "$tmp")"
    }
}

define-command -docstring 'fuzzy-find changed pull request files with fzf' gh-pr-files-fzf %{
    gh-review-ensure-state
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        resolve_review_section_path() {
            [ -n "$kak_buffile" ] && [ -f "$kak_buffile" ] || return 1
            awk -v target="$kak_cursor_line" '
NR > target { exit }
/^diff --git / {
    old = ""
    new = ""
    path = ""
    next
}
/^--- / {
    old = substr($0, 5)
    if (old == "/dev/null") {
        old = ""
    } else if (index(old, "a/") == 1) {
        old = substr(old, 3)
    }
    next
}
/^\+\+\+ / {
    new = substr($0, 5)
    if (new == "/dev/null") {
        new = ""
    } else if (index(new, "b/") == 1) {
        new = substr(new, 3)
    }
    path = (new != "" ? new : old)
}
END {
    if (path != "") {
        print path
    }
}' "$kak_buffile"
        }

        helper_path="${HOME}/.local/bin/kak-picker-gh-pr-files-fzf"
        [ -x "$helper_path" ] || {
            printf "fail %s\n" "$(kakquote "picker helper not found: $helper_path")"
            exit
        }

        [ -n "$kak_opt_gh_review_picker_root" ] && [ -d "$kak_opt_gh_review_picker_root" ] || {
            printf "fail %s\n" "$(kakquote "no changed-file picker state is available")"
            exit
        }
        [ -n "$kak_opt_gh_review_manifest_file" ] && [ -f "$kak_opt_gh_review_manifest_file" ] || {
            printf "fail %s\n" "$(kakquote "no changed-file manifest is available")"
            exit
        }

        tmp=$(mktemp "${TMPDIR:-/tmp}/kak-gh-fzf-picker.XXXXXX") || {
            printf "fail %s\n" "$(kakquote "unable to create a temporary picker launcher")"
            exit
        }

        session_q=$(printf '%s' "$kak_session" | sed "s/'/'\\\\''/g")
        client_q=$(printf '%s' "$kak_client" | sed "s/'/'\\\\''/g")
        manifest_q=$(printf '%s' "$kak_opt_gh_review_manifest_file" | sed "s/'/'\\\\''/g")
        helper_q=$(printf '%s' "$helper_path" | sed "s/'/'\\\\''/g")
        cwd_q=$(printf '%s' "$PWD" | sed "s/'/'\\\\''/g")
        start_path=$kak_opt_gh_review_picker_root
        if [ -n "$kak_opt_gh_review_section_path" ]; then
            candidate=$kak_opt_gh_review_picker_root/$kak_opt_gh_review_section_path
            if [ -e "$candidate" ]; then
                start_path=$candidate
            fi
        elif [ "$kak_opt_gh_review_buffer" = "true" ]; then
            relpath=$(resolve_review_section_path 2>/dev/null || true)
            if [ -n "$relpath" ]; then
                candidate=$kak_opt_gh_review_picker_root/$relpath
                if [ -e "$candidate" ]; then
                    start_path=$candidate
                fi
            fi
        elif [ -n "$kak_buffile" ] && [ -n "$kak_opt_gh_review_repo_root" ]; then
            case "$kak_buffile" in
                "$kak_opt_gh_review_repo_root"/*)
                    relpath=${kak_buffile#"$kak_opt_gh_review_repo_root"/}
                    candidate=$kak_opt_gh_review_picker_root/$relpath
                    if [ -e "$candidate" ]; then
                        start_path=$candidate
                    fi
                    ;;
            esac
        fi
        start_q=$(printf '%s' "$start_path" | sed "s/'/'\\\\''/g")

        cat >"$tmp" << SHELL
#!/bin/sh
export KAK_PICKER_SESSION='$session_q'
export KAK_PICKER_CLIENT='$client_q'
export KAK_GH_PICKER_MANIFEST='$manifest_q'
export KAK_GH_PICKER_START='$start_q'
cd '$cwd_q' || exit 1
'$helper_q'
status=\$?
rm -f '$tmp'
exit "\$status"
SHELL

        chmod +x "$tmp"
        printf "tmux-terminal-vertical sh %s\n" "$(kakquote "$tmp")"
    }
}

define-command -docstring 'open the current pull request in a browser with gh' gh-pr-view-web %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        command -v gh >/dev/null 2>&1 || {
            printf "fail %s\n" "$(kakquote "gh command not found in PATH")"
            exit
        }

        review_pr=$kak_opt_gh_review_pr_number
        repo_root=$kak_opt_gh_review_repo_root
        if [ -z "$repo_root" ] || ! git -C "$repo_root" rev-parse --show-toplevel >/dev/null 2>&1; then
            if [ -n "$kak_buffile" ] && [ -e "$kak_buffile" ]; then
                repo_dir=${kak_buffile%/*}
                repo_root=$(git -C "$repo_dir" rev-parse --show-toplevel 2>/dev/null || true)
            fi
        fi

        [ -n "$repo_root" ] || {
            printf "fail %s\n" "$(kakquote "unable to resolve a git repository for the current review context")"
            exit
        }

        if ! (
            cd "$repo_root" || exit 1
            if [ -n "$review_pr" ]; then
                gh pr view "$review_pr" --web >/dev/null 2>&1
            else
                gh pr view --web >/dev/null 2>&1
            fi
        ); then
            printf "fail %s\n" "$(kakquote "unable to open the current pull request in a browser")"
            exit
        fi
    }
}

define-command -docstring 'jump to the next hunk in the current review buffer' gh-next-hunk %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        [ -n "$kak_buffile" ] && [ -f "$kak_buffile" ] || {
            printf "fail %s\n" "$(kakquote "current review buffer is not backed by a diff file")"
            exit
        }

        hunks=$(awk '/^@@ / { print NR }' "$kak_buffile")
        [ -n "$hunks" ] || {
            printf "fail %s\n" "$(kakquote "no review hunks found in the current buffer")"
            exit
        }

        next_hunk=
        first_hunk=
        while IFS= read -r hunk; do
            [ -n "$hunk" ] || continue
            [ -n "$first_hunk" ] || first_hunk=$hunk
            if [ "$hunk" -gt "$kak_cursor_line" ]; then
                next_hunk=$hunk
                break
            fi
        done <<EOF
$hunks
EOF

        wrapped=false
        if [ -z "$next_hunk" ]; then
            next_hunk=$first_hunk
            wrapped=true
        fi

        printf "select %s.1,%s.1\n" "$next_hunk" "$next_hunk"
        if [ "$wrapped" = true ]; then
            printf "echo -markup '{Information}review hunk search wrapped around buffer'\n"
        fi
    }
}

define-command -docstring 'jump to the previous hunk in the current review buffer' gh-prev-hunk %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        [ -n "$kak_buffile" ] && [ -f "$kak_buffile" ] || {
            printf "fail %s\n" "$(kakquote "current review buffer is not backed by a diff file")"
            exit
        }

        hunks=$(awk '/^@@ / { print NR }' "$kak_buffile")
        [ -n "$hunks" ] || {
            printf "fail %s\n" "$(kakquote "no review hunks found in the current buffer")"
            exit
        }

        prev_hunk=
        last_hunk=
        while IFS= read -r hunk; do
            [ -n "$hunk" ] || continue
            last_hunk=$hunk
            if [ "$hunk" -lt "$kak_cursor_line" ]; then
                prev_hunk=$hunk
            fi
        done <<EOF
$hunks
EOF

        wrapped=false
        if [ -z "$prev_hunk" ]; then
            prev_hunk=$last_hunk
            wrapped=true
        fi

        printf "select %s.1,%s.1\n" "$prev_hunk" "$prev_hunk"
        if [ "$wrapped" = true ]; then
            printf "echo -markup '{Information}review hunk search wrapped around buffer'\n"
        fi
    }
}

define-command -docstring 'open the current diff location in the working tree file' gh-diff-open-working-tree-file %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        require_repo_root() {
            if [ -n "$kak_opt_gh_review_repo_root" ] && \
                git -C "$kak_opt_gh_review_repo_root" rev-parse --show-toplevel >/dev/null 2>&1; then
                printf '%s\n' "$kak_opt_gh_review_repo_root"
                return 0
            fi
            git rev-parse --show-toplevel 2>/dev/null
        }

        section_path=$kak_opt_gh_review_section_path
        if [ -z "$section_path" ]; then
            section_path=$(
                awk -v target="$kak_cursor_line" '
NR > target { exit }
/^diff --git / {
    old = ""
    new = ""
    path = ""
    next
}
/^--- / {
    old = substr($0, 5)
    if (old == "/dev/null") {
        old = ""
    } else if (index(old, "a/") == 1) {
        old = substr(old, 3)
    }
    next
}
/^\+\+\+ / {
    new = substr($0, 5)
    if (new == "/dev/null") {
        new = ""
    } else if (index(new, "b/") == 1) {
        new = substr(new, 3)
    }
    path = (new != "" ? new : old)
}
END {
    if (path != "") {
        print path
    }
}' "$kak_buffile"
            )
        fi

        [ -n "$section_path" ] || {
            printf "fail %s\n" "$(kakquote "unable to resolve the current diff section path")"
            exit
        }

        repo_root=$(require_repo_root) || {
            printf "fail %s\n" "$(kakquote "unable to resolve a git repository for the current review context")"
            exit
        }

        target_file=$repo_root/$section_path
        if [ ! -e "$target_file" ]; then
            printf "fail %s\n" "$(kakquote "working tree file does not exist for this diff section: $section_path")"
            exit
        fi

        printf "require-module diff\n"
        printf "diff-jump %s\n" "$(kakquote "$repo_root")"
    }
}
