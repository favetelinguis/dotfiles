FROM alpine

WORKDIR /root

# Install bash
RUN apk add bash

# Install git
RUN apk add git

# Install gitstatus might not need this if I just stray in vim
#RUN apk add gitstatus
#RUN git clone --depth=1 https://github.com/romkatv/gitstatus.git /usr/local/gitstatus
#RUN echo 'source /usr/local/gitstatus/gitstatus.prompt.sh' >> ~/.bashrc

# Install nvim
RUN apk add neovim

# Install zellij
#RUN apk add zellij
#RUN echo 'export SHELL=bash' >> /root/.bashrc # required by zellij

# TODO clone my dot-files and put them in correct folders then remove

# Install rtx - install this last
RUN apk add rtx --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
RUN echo 'eval "$(/usr/bin/rtx activate bash)"' >> /root/.bashrc # This should be the last line in .bashrc
RUN apk add curl # required by rtx install
# ~/.config/rtx/..rtx.toml \

# Set $HOME as workdir, all commands after this will be run in home, default is /

ENTRYPOINT ["/bin/bash"]
# How do volumes work, can I change state in an image then between containers,
# Volumes vs bind mounts

# Install helix

# Get my helix config
# Get my zellij config
# Get my lua nvim config from old computer