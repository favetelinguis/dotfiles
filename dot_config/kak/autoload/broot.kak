## broot integration for Kakoune via tmux splits

define-command -hidden -params 2 broot-launch-picker %{
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
        picker_q=$(printf '%s' "$picker_path" | sed "s/'/'\\\\''/g")
        cwd_q=$(printf '%s' "$PWD" | sed "s/'/'\\\\''/g")
        buffer_path=${kak_buffile:-}
        buffer_q=$(printf '%s' "$buffer_path" | sed "s/'/'\\\\''/g")

        cat >"$tmp" << SHELL
#!/bin/sh
export KAK_PICKER_SESSION='$session_q'
export KAK_PICKER_CLIENT='$client_q'
export KAK_PICKER_BUFFERFILE='$buffer_q'
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

define-command broot-files -docstring 'browse files with broot; Enter opens, q quits' %{
    broot-launch-picker kak-picker-broot kak-broot-files
}
