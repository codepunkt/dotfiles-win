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

spinner_start "updating packages"
apt update -qq &> /dev/null && \
    apt dist-upgrade -y -qq &> /dev/null && \
    apt autoremove -y -qq &> /dev/null && \
    apt autoclean -y -qq &> /dev/null
spinner_stop

spinner_start "installing additional packages"
apt -y -qq install \
    zsh \
    git \
    &> /dev/null
spinner_stop

spinner_start "updating dotfiles"
git pull -y &> /dev/null
spinner_stop

file="$HOME/.ssh/id_rsa.pub"
if [ ! -f "$file" ];
then
    spinner_start "creating ssh key"
	ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa  &> /dev/null
    spinner_stop
fi
