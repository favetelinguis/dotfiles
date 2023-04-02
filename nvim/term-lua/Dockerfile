# Run the image in brew install --cask kitty

FROM ubuntu:22.10

# build-essential ,git, curl is needed for curl
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git

# Install brew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"

# gcc is recomended by brew
RUN brew install \
    gcc \
    neovim \
    git-delta \
    ripgrep \
    fzf \
    autojump \
    exa


# Setup all config for tools work in my homerepo
WORKDIR /root
RUN mkdir -p /root/.config/{nvim}

RUN git clone https://github.com/favetelinguis/dotfiles.git
