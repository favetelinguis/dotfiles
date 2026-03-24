## fzf integration for Kakoune via tmux splits
## Requires: fzf, fd (or find), rg — all running inside tmux

define-command -hidden -params 2 fzf-launch-picker %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }

        picker=$1
        tmp_prefix=$2
        picker_path="${HOME}/.local/bin/${picker}"

        [ -x "$picker_path" ] || {
            printf "fail %s\n" "$(kakquote "picker helper not found: $picker_path")"
            exit
        }

        tmp=$(mktemp "${TMPDIR:-/tmp}/${tmp_prefix}.XXXXXX") || {
            printf "fail %s\n" "$(kakquote "unable to create a temporary picker script")"
            exit
        }

        session_q=$(printf '%s' "$kak_session" | sed "s/'/'\\\\''/g")
        client_q=$(printf '%s' "$kak_client" | sed "s/'/'\\\\''/g")
        pane_q=$(printf '%s' "${kak_client_env_TMUX_PANE:-}" | sed "s/'/'\\\\''/g")
        picker_q=$(printf '%s' "$picker_path" | sed "s/'/'\\\\''/g")
        cwd_q=$(printf '%s' "$PWD" | sed "s/'/'\\\\''/g")

        cat >"$tmp" << SHELL
#!/bin/sh
export KAK_PICKER_SESSION='$session_q'
export KAK_PICKER_CLIENT='$client_q'
export KAK_PICKER_ORIGINAL_PANE='$pane_q'
cd '$cwd_q' || exit 1
'$picker_q'
status=\$?
rm -f '$tmp'
exit "\$status"
SHELL

        chmod +x "$tmp"
        printf "tmux-terminal-vertical sh %s\n" "$(kakquote "$tmp")"
    }
}

define-command fzf-files -docstring 'fuzzy-find a file and open it' %{
    fzf-launch-picker kak-picker-files kak-fzf-files
}

define-command fzf-buffers -docstring 'fuzzy-pick an open buffer and switch to it' %{
    evaluate-commands %sh{
        session="$kak_session"
        client="$kak_client"
        buflist="$kak_quoted_buflist"
        tmp=$(mktemp /tmp/kak-fzf-buffers-XXXXXX)
        cat > "$tmp" << SHELL
#!/bin/sh
cd "$PWD"
eval "set -- $buflist"
result=\$(printf '%s\n' "\$@" | fzf --reverse --border --prompt 'buffers> ')
[ -z "\$result" ] && rm -f "$tmp" && exit
kak_buf=\$(printf '%s' "\$result" | sed "s/'/''/g")
printf "evaluate-commands -client '$client' 'buffer ''%s'''\n" "\$kak_buf" | kak -p '$session'
rm -f "$tmp"
SHELL
        chmod +x "$tmp"
        kak_tmp=$(printf '%s' "$tmp" | sed "s/'/''/g")
        printf "tmux-terminal-vertical sh '%s'\n" "$kak_tmp"
    }
}

define-command fzf-grep -docstring 'live-grep files with fzf, jump to match' %{
    fzf-launch-picker kak-picker-grep kak-fzf-grep
}

define-command fzf-directories -docstring 'fuzzy-find a directory and open Kakoune there' %{
    fzf-launch-picker kak-picker-directories kak-fzf-directories
}
