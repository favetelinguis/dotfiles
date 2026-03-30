# Zenburn UI with Alabaster-style syntax restraint.
source "%val{runtime}/colors/zenburn.kak"

# Only keep Alabaster's four highlighted syntax categories, using Zenburn colors.
set-face global string rgb:7f9f7f
set-face global value rgb:dca3a3
set-face global comment rgb:efef8f
set-face global documentation comment
set-face global function rgb:8cd0d3
set-face global type rgb:8cd0d3
set-face global module rgb:8cd0d3

# Everything else falls back to the base text color.
set-face global keyword Default
set-face global operator Default
set-face global attribute Default
set-face global meta Default
set-face global builtin Default
set-face global variable Default
