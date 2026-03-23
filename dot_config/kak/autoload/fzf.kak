
## fzf integration for Kakoune via tmux splits
## Requires: fzf, fd (or find), rg — all running inside tmux

# ── helpers ──────────────────────────────────────────────────────────────────

# Write a self-contained shell script to a temp file and return its path.
# Each fzf-* command uses this pattern to avoid multi-level quoting hell.

# ── fzf-files ────────────────────────────────────────────────────────────────

define-command fzf-files -docstring 'fuzzy-find a file and open it' %{
    evaluate-commands %sh{
        session="$kak_session"
        client="$kak_client"
        original_pane="${kak_client_env_TMUX_PANE:-}"
        split_helper="${HOME}/.local/bin/kak-fzf-split-open"
        tmp=$(mktemp /tmp/kak-fzf-files-XXXXXX)
        # Heredoc: $session/$client/$PWD/$original_pane expand here; \$... is literal $ in script
        cat > "$tmp" << SHELL
#!/bin/sh
cd "$PWD"
result=\$( (fd --type f 2>/dev/null || find . -type f) | \
    fzf --reverse --border \
        --header 'enter: open  ╱  ctrl-o: open in split' \
        --bind "ctrl-o:execute-silent($split_helper '$session' '$original_pane' {})+abort")
[ -z "\$result" ] && rm -f "$tmp" && exit
kak_path=\$(printf '%s' "\$result" | sed "s/'/''/g")
printf "evaluate-commands -client '$client' 'edit -existing ''%s'''\n" "\$kak_path" | kak -p '$session'
rm -f "$tmp"
SHELL
        chmod +x "$tmp"
        kak_tmp=$(printf '%s' "$tmp" | sed "s/'/''/g")
        printf "tmux-terminal-vertical sh '%s'\n" "$kak_tmp"
    }
}

# ── fzf-buffers ──────────────────────────────────────────────────────────────

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
result=\$(printf '%s\n' "\$@" | fzf --reverse --border)
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

# ── fzf-grep ─────────────────────────────────────────────────────────────────

define-command fzf-grep -docstring 'live-grep files with fzf, jump to match' %{
    evaluate-commands %sh{
        session="$kak_session"
        client="$kak_client"
        original_pane="${kak_client_env_TMUX_PANE:-}"
        split_helper="${HOME}/.local/bin/kak-fzf-split-open"
        tmp=$(mktemp /tmp/kak-fzf-grep-XXXXXX)
        cat > "$tmp" << SHELL
#!/bin/sh
cd "$PWD"
result=\$(rg --line-number --no-heading --with-filename --smart-case -- '' | \
    fzf --disabled --reverse --border --prompt 'grep> ' \
        --header 'enter: open  ╱  ctrl-o: open in split' \
        --bind "ctrl-o:execute-silent($split_helper '$session' '$original_pane' {})+abort" \
        --bind 'change:reload:rg --line-number --no-heading --with-filename --smart-case -- {q} || true')
[ -z "\$result" ] && rm -f "$tmp" && exit
filepath=\$(printf '%s' "\$result" | cut -d: -f1)
lineno=\$(printf '%s' "\$result" | cut -d: -f2)
kak_path=\$(printf '%s' "\$filepath" | sed "s/'/''/g")
printf "evaluate-commands -client '$client' 'edit -existing ''%s'' %s'\n" "\$kak_path" "\$lineno" | kak -p '$session'
rm -f "$tmp"
SHELL
        chmod +x "$tmp"
        kak_tmp=$(printf '%s' "$tmp" | sed "s/'/''/g")
        printf "tmux-terminal-vertical sh '%s'\n" "$kak_tmp"
    }
}

# ── fzf-git-branch ───────────────────────────────────────────────────────────

define-command fzf-git-branch -docstring 'fuzzy-pick a git branch and check it out' %{
    evaluate-commands %sh{
        session="$kak_session"
        client="$kak_client"
        tmp=$(mktemp /tmp/kak-fzf-branch-XXXXXX)
        cat > "$tmp" << SHELL
#!/bin/sh
cd "$PWD"
result=\$(git branch --all --format='%(refname:short)' 2>/dev/null | fzf --reverse --border)
[ -z "\$result" ] && rm -f "$tmp" && exit
out=\$(git checkout "\$result" 2>&1)
msg=\$(printf '%s' "\$out" | head -3 | sed "s/'/''/g")
printf "evaluate-commands -client '$client' 'echo -markup ''{Information}%s'''\n" "\$msg" | kak -p '$session'
rm -f "$tmp"
SHELL
        chmod +x "$tmp"
        kak_tmp=$(printf '%s' "$tmp" | sed "s/'/''/g")
        printf "tmux-terminal-vertical sh '%s'\n" "$kak_tmp"
    }
}

# ── key bindings ─────────────────────────────────────────────────────────────

declare-user-mode fzf
map global user f ':enter-user-mode fzf<ret>' -docstring 'fzf'
map global fzf f ':fzf-files<ret>'            -docstring 'files'
map global fzf b ':fzf-buffers<ret>'          -docstring 'buffers'
map global fzf g ':fzf-grep<ret>'             -docstring 'grep'
map global fzf B ':fzf-git-branch<ret>'       -docstring 'git branch'
