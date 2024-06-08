# Register my global gitignore with gitconfig
global-gitignore:
    git config --global core.excludesfile '~/.gitignore_global'

# Install doom emacs
doom-emacs:
    git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs && doom install

# Will first rebuild the image and then recreate the distrobox based on the ini file
make-distrobox NAME='emacs':
   #!/usr/bin/env bash
   set -euxo pipefail
   if command -v docker &> /dev/null; then
       echo "Docker installation found"
       docker build --progress plain --no-cache -f ./distroboxes/TumbleweedL1{{NAME}} -t {{NAME}}devbox . && \
       distrobox assemble create --file ./distroboxes/distrobox.ini -n {{NAME}}Devbox
   elif command -v podman &> /dev/null; then
       echo "Podman installation found"
       podman build --no-cache -f ./distroboxes/TumbleweedL1{{NAME}} -t {{NAME}}devbox .
   else
       echo "Docker or podman installation not found."
       exit 1
   fi

# Install Java
java:
    asdf plugin-add java https://github.com/halcyon/asdf-java.git

# Install Clojure
clojure: java
    asdf plugin add clojure https://github.com/asdf-community/asdf-clojure.git

# Install NodeJs
node:
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
