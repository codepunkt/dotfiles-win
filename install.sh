#!/bin/bash

checkmark="$(tput setaf 2)✔$(tput sgr0)"

spinner_abort() {
  [ -n "$SPINNER_PID" ] && kill $SPINNER_PID
  echo -e '\033[?25h'
  exit 0
}

spinner_loop() {
  while true; do
    let 'SPINNER_INDEX=++SPINNER_INDEX % SPINNER_LENGTH'
    echo -en "$(tput setaf 3)${SPINNER_FRAMES[$SPINNER_INDEX]}$(tput sgr0) ${1}\033[1D"\\r
    sleep 0.1
  done
}

spinner_start() {
  SPINNER_FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  SPINNER_INDEX=0
  SPINNER_LENGTH=${#SPINNER_FRAMES[@]}

  trap spinner_abort SIGINT
  echo -en '\033[?25l'
  spinner_loop "${1}" &
  SPINNER_PID=$!
  sleep 0.1
}

spinner_stop() {
  kill $SPINNER_PID &> /dev/null
  wait $SPINNER_PID &> /dev/null
  echo -e "$checkmark\033[?25h"
}

# store current user
THIS_USER=`pstree -lu -s $$ | grep --max-count=1 -o '([^)]*)' | head -n 1 | sed 's/[()]//g'`

# require sudo privileges
if [ $EUID != 0 ]; then
  sudo "$0" "$@"
  exit $?
fi

# update packages
spinner_start "updating packages"
sudo apt update -qq &> /dev/null && \
  sudo apt dist-upgrade -y -qq &> /dev/null && \
  sudo apt autoremove -y -qq &> /dev/null && \
  sudo apt autoclean -y -qq &> /dev/null
spinner_stop

# install packages
spinner_start "installing additional packages"
sudo apt -y -qq install \
  apt-transport-https \
  build-essential \
  ca-certificates \
  curl \
  git \
  python-pip \
  software-properties-common \
  zsh \
  &> /dev/null
spinner_stop

# dotfiles
if [ -d ~/.dotfiles ]; then
  spinner_start "pulling dotfile updates"
  cd ~/.dotfiles && \
    git pull &> /dev/null && \
    cd -
  spinner_stop
else
  spinner_start "cloning dotfiles"
  git clone https://github.com/codepunkt/dotfiles-win.git ~/.dotfiles &> /dev/null
  spinner_stop
fi

# ssh key
pubKey="$HOME/.ssh/id_rsa"
if [ ! -f "$pubKey" ]; then
  spinner_start "creating ssh key"
  ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa  &> /dev/null
  spinner_stop
else
  echo "$checkmark ssh key exists"
fi

# docker
if [ -x "$(command -v docker)" ]; then
  echo "$checkmark docker is installed"
else
  spinner_start "installing docker"
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &> /dev/null && \
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &> /dev/null && \
    sudo apt update -qq &> /dev/null && \
    sudo apt install docker-ce -y -qq &> /dev/null
  spinner_stop
fi

# oh-my-zsh
if [ -d ~/.oh-my-zsh ]; then
  spinner_start "pulling oh-my-zsh updates"
  cd ~/.oh-my-zsh && \
    git pull &> /dev/null && \
    cd - &> /dev/null
  spinner_stop
else
  spinner_start "installing oh-my-zsh"
  git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh &> /dev/null
  spinner_stop
fi

# optional: link zsh themes that come with this repo

# zsh syntax highlighting
if [ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
  spinner_start "pulling zsh-syntax-highlighting updates"
  cd ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    git pull &> /dev/null && \
    cd - &> /dev/null
  spinner_stop
else
  spinner_start "installing zsh-syntax-highlighting"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  spinner_stop
fi

# nvm
if [ -d ~/.dotfiles ]; then
  spinner_start "updating nvm"
  cd ~/.nvm && \
    git pull &> /dev/null && \
    cd - &> /dev/null
  spinner_stop
else
  spinner_start "installing nvm"
  curl -s -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash &> /dev/null
  spinner_stop
fi

# node
if [ -x "$(command -v docker)" ]; then
  spinner_start "updating node"
  sudo -Hu ${THIS_USER} bash -c '. ~/.nvm/nvm.sh && nvm i --lts --latest-npm' &> /dev/null
  spinner_stop
else
  spinner_start "installing node"
  nvm i --lts --latest-npm &> /dev/null
  spinner_stop
fi

# npm packages
spinner_start "installing npm packages"
sudo -Hu ${THIS_USER} bash -c '. ~/.nvm/nvm.sh && npm i -g yarn create-react-app np npm-name-cli tldr ndb yo fkill-cli' &> /dev/null
spinner_stop

# symlink config files
spinner_start "symlinking config files"
ln -sf ~/.dotfiles/.bashrc ~/.bashrc
ln -sf ~/.dotfiles/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/.gitconfig ~/.gitconfig
spinner_stop

# alias windows programs
if grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null; then
  spinner_start "symlinking windows programs"
  mkdir -p ~/.bin
  ln -sf /mnt/c/Program\ Files\ \(x86\)/Google/Chrome/Application/chrome.exe ~/.bin/chrome
  spinner_stop
fi
