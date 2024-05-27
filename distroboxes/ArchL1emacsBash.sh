if [[ "$(hostname)" == *"emacsDevbox"* ]]; then
    eval "$(direnv hook bash)"
    . /opt/asdf-vm/asdf.sh

    # Start my vanilla emacs config
    alias vemacs="emacs --init-directory ~/.config/emacs/my-emacs"

    # Added by Toolbox App
    export PATH="$PATH:/home/henriklarsson/.local/share/JetBrains/Toolbox/scripts"
fi
