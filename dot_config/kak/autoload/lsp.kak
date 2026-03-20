# Override default Python hook to use ty instead of pylsp
remove-hooks global lsp-filetype-python
hook global BufSetOption filetype=python %{
    set-option buffer lsp_servers %{
        [ty]
        command = "ty"
        args = ["server"]
        root_globs = ["pyproject.toml", "setup.py", "poetry.lock", ".git", ".hg"]
    }
}

# Enable LSP only for filetypes with installed servers
hook global WinSetOption filetype=(javascript|typescript|python|c|cpp|objc) %{
    lsp-enable-window
}

# Format on save for LSP-enabled filetypes
hook global BufSetOption filetype=(javascript|typescript|python|c|cpp|objc) %{
    hook buffer BufWritePre .* lsp-formatting-sync
}

# Highlight references to symbol under cursor
set-option global lsp_auto_highlight_references true
