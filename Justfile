# Register my global gitignore with gitconfig
global-gitignore:
    git config --global core.excludesfile '~/.gitignore_global'

# Install doom emacs
doom-emacs:
    git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs && doom install

# Will first rebuild the image and then recreate the distrobox based on the ini file
make-distrobox NAME:
    podman build --no-cache -f ./distroboxes/ArchL1{{NAME}} -t {{NAME}}devbox .
    distrobox assemble create --file ./distroboxes/distrobox.ini -n {{NAME}}Devbox

# Install Java
java:
    asdf plugin-add java https://github.com/halcyon/asdf-java.git

# Install Clojure
clojure: java
    asdf plugin add clojure https://github.com/asdf-community/asdf-clojure.git