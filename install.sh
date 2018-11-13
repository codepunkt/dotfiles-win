#!/bin/bash

spinner_abort() {
  [ -n "$SPINNER_PID" ] && kill $SPINNER_PID
  echo -e '\033[?25h'
  exit 0
}

spinner_loop() {
  while true; do
    let 'SPINNER_INDEX=++SPINNER_INDEX % SPINNER_LENGTH'
    echo -en "$(tput setaf 4)${SPINNER_FRAMES[$SPINNER_INDEX]}$(tput sgr0) ${1}\033[1D"\\r
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
}

spinner_stop() {
  kill $SPINNER_PID &> /dev/null
  wait $SPINNER_PID &> /dev/null
  echo -e "$(tput setaf 2)✔$(tput sgr0)\033[?25h"
}

if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# spinner_start "updating packages"
# sudo apt update -qq &> /dev/null && \
#     sudo apt dist-upgrade -y -qq &> /dev/null && \
#     sudo apt autoremove -y -qq &> /dev/null && \
#     sudo apt autoclean -y -qq &> /dev/null
# spinner_stop

# spinner_start "installing additional packages"
# sudo apt -y -qq install \
#     apt-transport-https \
#     build-essential \
#     ca-certificates \
#     curl \
#     git \
#     software-properties-common \
#     zsh \
#     &> /dev/null
# spinner_stop

# spinner_start "pulling dotfile updates"
# git pull -y &> /dev/null
# sleep 0.5
# spinner_stop

pubKey="$HOME/.ssh/id_rsa.pub"
if [ ! -f "$pubKey" ]; then
    spinner_start "creating ssh key"
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa  &> /dev/null
    spinner_stop
fi

# spinner_start "installing docker"
# sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &> /dev/null && \
#     sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &> /dev/null && \
#     sudo apt update -qq &> /dev/null && \
#     sudo apt install docker-ce -y -qq &> /dev/null
# spinner_stop

if builtin type -p nvm &> /dev/null; then
    echo "nvm already installed"
else
    spinner_start "installing node version manager"
    curl -s -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash &> /dev/null
    spinner_stop
fi
# if [ ! builtin type -p node ];
# then
#     nvm install --lts
# fi


# npm i -g npm yarn pure-prompt

#https://github.com/jieverson/dotfiles-win/blob/master/install.sh