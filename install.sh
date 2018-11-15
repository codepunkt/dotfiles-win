#!/usr/bin/env bash

{ # this ensures the entire script is downloaded #

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

install() {
  sudo echo "Installing codepunkt/dotfiles 🚀"
  echo ""

  # store current user
  THIS_USER=`pstree -lu -s $$ | grep --max-count=1 -o '([^)]*)' | head -n 1 | sed 's/[()]//g'`

  # update apt packages
  spinner_start "updating apt packages"
  sudo apt update -qq &> /dev/null && \
    sudo apt dist-upgrade -y -qq &> /dev/null && \
    sudo apt autoremove -y -qq &> /dev/null && \
    sudo apt autoclean -y -qq &> /dev/null
  spinner_stop

  # add apt repositories
  spinner_start "adding apt repositories"
  sudo apt-add-repository ppa:ansible/ansible &> /dev/null
  sudo apt update -qq &> /dev/null
  spinner_stop

  # install apt packages
  spinner_start "installing apt packages"
  sudo apt -y -qq install \
    ansible \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    git \
    jq \
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
      cd - &> /dev/null
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

  # zsh syntax highlighting
  if [ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
    spinner_start "pulling zsh-syntax-highlighting updates"
    cd ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
      git pull &> /dev/null && \
      cd - &> /dev/null
    spinner_stop
  else
    spinner_start "installing zsh-syntax-highlighting"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting &> /dev/null
    spinner_stop
  fi

  # nvm
  if [ -d ~/.nvm ]; then
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
  sudo -Hu ${THIS_USER} bash -c '. ~/.nvm/nvm.sh && npm i -g yarn create-react-app np npm-name-cli tldr ndb yo diff-so-fancy fkill-cli' &> /dev/null
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

  # bat
  if [ -x "$(command -v wat)" ]; then
    echo "$checkmark bat is installed"
  else
    spinner_start "installing bat"
    wget -O ~/bat_0.9.0_amd64.deb https://github.com/sharkdp/bat/releases/download/v0.9.0/bat_0.9.0_amd64.deb &> /dev/null
    sudo dpkg -i ~/bat_0.9.0_amd64.deb &> /dev/null
    rm -f ~/bat_0.9.0_amd64.deb &> /dev/null
    spinner_stop
  fi

  # z
  if [ -x "$(command -v z)" ]; then
    echo "$checkmark z is installed"
  else
    spinner_start "installing z"
    wget -O ~/z.sh https://raw.githubusercontent.com/rupa/z/master/z.sh &> /dev/null
    spinner_stop
  fi

  echo ""
  echo "Successfully installed codepunkt/dotfiles 🔥"
  echo "Don't forget to edit your ~/.gitconfig user information!"
}

install

} # this ensures the entire script is downloaded #