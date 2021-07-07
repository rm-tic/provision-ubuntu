#!/bin/bash

PLAY_USER="$USER"

function GTERM_LOAD()
{
  GTERM_DIR="$HOME/.gterm"
  GTERM_FILE="$GTERM_DIR/gterm-profile.dconf"
  GTERM_RC="$GTERM_DIR/gterm.rc"
  GTERM_URL="https://raw.githubusercontent.com/rm-tic/provision-ubuntu/master/gterm-profile.dconf"


  if [[ ! -d $GTERM_DIR  || "$(cat $GTERM_RC)" != "0" ]]; then
    mkdir $GTERM_DIR
    echo "0" > $GTERM_RC
    wget -qO $GTERM_FILE $GTERM_URL

  #DCONF EXPORT
  #dconf dump /org/gnome/terminal/legacy/profiles:/ > $GTERM_FILE

  #DCONF IMPORT
    dconf load /org/gnome/terminal/legacy/profiles:/ < $GTERM_FILE
  fi
}

function CHECK_INSTALL()
{
  PKG="$(dpkg-query -W -f='${db:Status-Abbrev}' $1 2> /dev/null | cut -c 1-2)"

  if [ "$PKG" = "ii" ]; then
    echo "present"
  else
    echo "absent"
  fi
}

function APT_UPDATE()
{
  if [ "$UPDATE_RC" != "0" ]; then
    sudo apt-get update -qq
    UPDATE_RC="0"
  fi
}

function INSTALL()
{
  GIT_STATUS="$(CHECK_INSTALL git)"
  PYTHON3_VENV_STATUS="$(CHECK_INSTALL python3-venv)"
  CURL_STATUS="$(CHECK_INSTALL curl)"

  echo "Installing Essential Packages..."
  echo

  if [ "$CURL_STATUS" = "absent" ]; then
    APT_UPDATE
    sudo apt-get install -y curl > /dev/null 2>&1
    echo ">> curl installed."
  else
    echo ">> curl is already installed."
  fi

  if [ "$PYTHON3_VENV_STATUS" = "absent" ]; then
    APT_UPDATE
    sudo apt-get install -y python3-virtualenv > /dev/null 2>&1
    echo ">> python3-venv installed."
  else
    echo ">> python3-venv is already installed."
  fi

  if [ "$GIT_STATUS" = "absent" ]; then
    APT_UPDATE
    sudo apt-get install -y git > /dev/null 2>&1
    echo ">> Git v$(git --version | awk '{print $3}') installed."
  else
    echo ">> Git is already installed."
  fi

  echo
}

function CLONE_REPO()
{
  REPO_DIR="/tmp/provision-ubuntu"
  REPO_URL="https://github.com/rm-tic/provision-ubuntu.git"

  echo "Cloning Repository in $REPO_DIR"
  git clone $REPO_URL $REPO_DIR > /dev/null 2>&1
  echo
}

function CREATE_VENV()
{
  python3 -m virtualenv "$REPO_DIR/.venv"
}

function ENABLE_VENV()
{
  source "$REPO_DIR/.venv/bin/activate"
}

function SETUP_VENV()
{
  python3 -m pip install -U -r "$REPO_DIR/requirements.txt"
}

function ANSIBLE_COLLECTION(){
  echo
  echo "Install community.general collection"
  echo
  ansible-galaxy collection install community.general
}

function EXEC_ANSIBLE()
{
  echo
  echo "Starting Playbook..."
  echo
  ansible-playbook "$REPO_DIR/main.yml"
}

function MAIN()
{
  echo
  echo "+----------------------------------+"
  echo "| Invencible (Ansible)             |"
  echo "| Project: provision-ubuntu        |"
  echo "| Author: Rodrigo Martins (IceTux) |"
  echo "| Creation Date: 2021-07-07        |"
  echo "+----------------------------------+"
  echo
  echo

  #Exec Functions
  GTERM_LOAD
  INSTALL
  CLONE_REPO
  CREATE_VENV
  ENABLE_VENV
  SETUP_VENV
  ANSIBLE_COLLECTION
  EXEC_ANSIBLE
}

MAIN