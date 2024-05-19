if [[ "$(hostname)" == *"emacsDevbox"* ]]; then
    eval "$(direnv hook bash)"
    . /opt/asdf-vm/asdf.sh

    # Added by Toolbox App
    export PATH="$PATH:/home/henriklarsson/.local/share/JetBrains/Toolbox/scripts"
fi
