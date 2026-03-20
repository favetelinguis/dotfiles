provide-module iflipb %{

declare-option -hidden str-list iflipb_mru_list
declare-option -hidden str-list iflipb_flip_snapshot
declare-option -hidden int      iflipb_flip_index 0
declare-option -hidden bool     iflipb_flipping false
declare-option           str    iflipb_ignore_regex '^\*'

# Move current buffer to front of MRU list. No-ops while flipping.
define-command -hidden iflipb-update-mru %{
    evaluate-commands %sh{
        [ "$kak_opt_iflipb_flipping" = "true" ] && exit 0
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        current="$kak_bufname"
        eval set -- $kak_quoted_opt_iflipb_mru_list
        new_list="$(kakquote "$current")"
        for buf; do
            [ "$buf" = "$current" ] && continue
            new_list="$new_list $(kakquote "$buf")"
        done
        printf 'set-option global iflipb_mru_list %s\n' "$new_list"
    }
}

# Append current buffer to the END of MRU list if not already present.
# Called from BufOpenFile/BufNewFile so all buffers are discoverable.
define-command -hidden iflipb-mru-append %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        current="$kak_bufname"
        eval set -- $kak_quoted_opt_iflipb_mru_list
        for buf; do
            [ "$buf" = "$current" ] && exit 0
        done
        new_list=""
        for buf; do
            new_list="${new_list:+$new_list }$(kakquote "$buf")"
        done
        new_list="${new_list:+$new_list }$(kakquote "$current")"
        printf 'set-option global iflipb_mru_list %s\n' "$new_list"
    }
}

define-command iflipb-next-buffer \
    -docstring 'flip to next (older) buffer in MRU order (j)' %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        eval set -- $kak_quoted_opt_iflipb_flip_snapshot
        idx=$kak_opt_iflipb_flip_index
        total=$#
        next=$((idx + 1))
        if [ "$next" -ge "$total" ]; then
            printf "echo -markup '{Information}iflipb: at end of list'\n"
            exit 0
        fi
        printf 'set-option global iflipb_flip_index %d\n' "$next"
        i=0
        for buf; do
            if [ "$i" -eq "$next" ]; then
                printf 'buffer %s\n' "$(kakquote "$buf")"
                break
            fi
            i=$((i + 1))
        done
        i=0; markup=""
        for buf; do
            if [ -n "$markup" ]; then markup="$markup "; fi
            if [ "$i" -eq "$next" ]; then
                markup="${markup}{PrimarySelection}[$buf]{Default}"
            else
                markup="$markup$buf"
            fi
            i=$((i + 1))
        done
        printf 'echo -markup %s\n' "$(kakquote "$markup")"
    }
    iflipb-prompt
}

define-command iflipb-previous-buffer \
    -docstring 'flip to previous (newer) buffer in MRU order (k)' %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        eval set -- $kak_quoted_opt_iflipb_flip_snapshot
        idx=$kak_opt_iflipb_flip_index
        if [ "$idx" -le 0 ]; then
            printf "echo -markup '{Information}iflipb: already at newest'\n"
            exit 0
        fi
        prev=$((idx - 1))
        printf 'set-option global iflipb_flip_index %d\n' "$prev"
        i=0
        for buf; do
            if [ "$i" -eq "$prev" ]; then
                printf 'buffer %s\n' "$(kakquote "$buf")"
                break
            fi
            i=$((i + 1))
        done
        i=0; markup=""
        for buf; do
            if [ -n "$markup" ]; then markup="$markup "; fi
            if [ "$i" -eq "$prev" ]; then
                markup="${markup}{PrimarySelection}[$buf]{Default}"
            else
                markup="$markup$buf"
            fi
            i=$((i + 1))
        done
        printf 'echo -markup %s\n' "$(kakquote "$markup")"
    }
    iflipb-prompt
}

define-command iflipb-kill-buffer \
    -docstring 'kill current buffer and continue flipping' %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        current="$kak_bufname"

        eval set -- $kak_quoted_opt_iflipb_mru_list
        new_mru=""
        for buf; do
            [ "$buf" = "$current" ] && continue
            new_mru="${new_mru:+$new_mru }$(kakquote "$buf")"
        done

        eval set -- $kak_quoted_opt_iflipb_flip_snapshot
        idx=$kak_opt_iflipb_flip_index

        new_list=""; new_count=0
        for buf; do
            [ "$buf" = "$current" ] && continue
            new_list="${new_list:+$new_list }$(kakquote "$buf")"
            new_count=$((new_count + 1))
        done

        printf 'set-option global iflipb_mru_list %s\n' "$new_mru"

        if [ "$new_count" -eq 0 ]; then
            printf 'delete-buffer\n'
            printf 'iflipb-end-flip\n'
            exit 0
        fi

        new_idx=$idx
        [ "$new_idx" -ge "$new_count" ] && new_idx=$((new_count - 1))

        printf 'set-option global iflipb_flip_snapshot %s\n' "$new_list"
        printf 'set-option global iflipb_flip_index %d\n' "$new_idx"

        eval set -- $new_list
        i=0
        for buf; do
            if [ "$i" -eq "$new_idx" ]; then
                printf 'buffer %s\n' "$(kakquote "$buf")"
                break
            fi
            i=$((i + 1))
        done
        printf 'delete-buffer %s\n' "$(kakquote "$current")"

        i=0; markup=""
        for buf; do
            if [ -n "$markup" ]; then markup="$markup "; fi
            if [ "$i" -eq "$new_idx" ]; then
                markup="${markup}{PrimarySelection}[$buf]{Default}"
            else
                markup="$markup$buf"
            fi
            i=$((i + 1))
        done
        printf 'echo -markup %s\n' "$(kakquote "$markup")"
        printf 'iflipb-prompt\n'
    }
}

define-command -hidden iflipb-end-flip %{
    set-option global iflipb_flipping false
    set-option global iflipb_flip_snapshot
    set-option global iflipb_flip_index 0
    iflipb-update-mru
}

hook -group iflipb global WinDisplay  .* %{ iflipb-update-mru }
hook -group iflipb global BufOpenFile .* %{ iflipb-mru-append }
hook -group iflipb global BufNewFile  .* %{ iflipb-mru-append }

hook -group iflipb global BufClose .* %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        closed="$kak_hook_param"
        eval set -- $kak_quoted_opt_iflipb_mru_list
        new_list=""
        for buf; do
            [ "$buf" = "$closed" ] && continue
            new_list="${new_list:+$new_list }$(kakquote "$buf")"
        done
        printf 'set-option global iflipb_mru_list %s\n' "$new_list"
    }
}

define-command -hidden iflipb-prompt %{
    on-key %{
        evaluate-commands %sh{
            kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
            case "$kak_key" in
                n) printf 'iflipb-next-buffer\n' ;;
                p) printf 'iflipb-previous-buffer\n' ;;
                d) printf 'iflipb-kill-buffer\n' ;;
                *) printf 'iflipb-end-flip\nexecute-keys %s\n' "$(kakquote "$kak_key")" ;;
            esac
        }
    }
}

define-command iflipb-start \
    -docstring 'start a buffer flip session' %{
    evaluate-commands %sh{
        kakquote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"; }
        regex="$kak_opt_iflipb_ignore_regex"
        eval set -- $kak_quoted_opt_iflipb_mru_list
        filtered=""; count=0
        for buf; do
            printf '%s' "$buf" | grep -qE "$regex" 2>/dev/null && continue
            filtered="${filtered:+$filtered }$(kakquote "$buf")"
            count=$((count + 1))
        done
        if [ "$count" -eq 0 ]; then
            printf "echo -markup '{Error}iflipb: no buffers to flip'\n"
            exit 0
        fi
        if [ "$count" -eq 1 ]; then
            printf "echo -markup '{Information}iflipb: only one buffer'\n"
            exit 0
        fi
        printf 'set-option global iflipb_flipping true\n'
        printf 'set-option global iflipb_flip_index 1\n'
        printf 'set-option global iflipb_flip_snapshot %s\n' "$filtered"
        eval set -- $filtered
        i=0
        for buf; do
            if [ "$i" -eq 1 ]; then
                printf 'buffer %s\n' "$(kakquote "$buf")"
                break
            fi
            i=$((i + 1))
        done
        i=0; markup=""
        for buf; do
            if [ -n "$markup" ]; then markup="$markup "; fi
            if [ "$i" -eq 1 ]; then
                markup="${markup}{PrimarySelection}[$buf]{Default}"
            else
                markup="$markup$buf"
            fi
            i=$((i + 1))
        done
        printf 'echo -markup %s\n' "$(kakquote "$markup")"
        printf 'iflipb-prompt\n'
    }
}

map global normal <a-j> ': iflipb-start<ret>' \
    -docstring 'buffer flip (MRU)'

}

require-module iflipb
