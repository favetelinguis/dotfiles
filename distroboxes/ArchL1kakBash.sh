if [[ "$(hostname)" == *"kakDevbox"* ]]; then
    export EDITOR=kak
    export PAGER=bat
    eval "$(starship init bash)"
    eval "$(mise activate bash)"

    # If tmux is installed and we are not in tmux start tmux
    if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
      exec tmux
    fi

    eval "$(fzf --bash)"
    export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_TMUX_OPTS='-p80%,60%'

    source ~/fzf_commands.sh

    alias ll="eza -lha"
    alias ls="eza"
    alias tree="eza --tree --all"
fi
