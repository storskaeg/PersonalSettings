#!/usr/bin/env bash

function pause() {
  read -n 1 -s -r -p "Press any key to continue..."
}

function sleep_3min() {
  sleep 180
}

SUDO=''
if (( $EUID != 0 )); then
  SUDO='sudo'
fi

# Determine OS platform
echo "Determining OS..."
UNAME=$(uname | tr "[:upper:]" "[:lower:]")
# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
    # If available, use LSB to identify distribution
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'// | awk '{print tolower($0)}')
    # Otherwise, use release info file
    else
        export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1 | awk '{print tolower($0)}')
    fi
fi
# For everything else (or if above failed), just use generic identifier
[ "$DISTRO" == "" ] && export DISTRO=$UNAME
echo $DISTRO
unset UNAME

if [ "$DISTRO" == "darwin" ]; then
  # Do something under Mac OS X
  echo "Identified MacOS"
  echo "This script will run for a bit, but occasionally require your input."
  pause

  # Dev Tools
  echo "Installing and activating devtools..."
  $SUDO xcode-select --install
  # xcode-select -s /Applications/Xcode.app/Contents/Developer
  $SUDO xcodebuild -license accept

  # Homebrew
  echo "Installing Homebrew..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  # The basics: basic tooling, standard datastores and caching, and helpers
  echo "Installing the basics from Homebrew..."
  echo "We'll wait for a few and pause after this."
  brew update
  brew install curl dep git git-delta go heroku jfrog-cli-go kubernetes-cli mariadb memcached postgresql rbenv redis ruby-build sqlite srcclr tmux vim wget
  brew tap heroku/brew && brew install heroku
  brew tap AdoptOpenJDK/openjdk && brew cask install adoptopenjdk8
  brew cask install insomnia

  # Attempting to mitigate race condition by sleeping 3 minutes while homebrew completes, then waiting for the user to provide input
  sleep_3min
  pause

  # Start the services
  # TODO: There's a race condition, here. We attempt to start the services before installation has completed.
  echo "Activating services..."
  brew services start mariadb
  brew services start memcached
  brew services start postgresql
  brew services start redis
  brew services start sqlite

  # ZSH -- separated from the earlier installs so it can be commented out in needed
  echo "Installing zsh..."
  brew install zsh
  
  # MacOS  Bluetooth Audio Fixes
  # Credits: https://apple.stackexchange.com/questions/167245/yosemite-bluetooth-audio-is-choppy-skips
  defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Max (editable)" 80
  defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" 48
  defaults write com.apple.BluetoothAudioAgent "Apple Initial Bitpool (editable)" 40
  defaults write com.apple.BluetoothAudioAgent "Negotiated Bitpool" 58
  defaults write com.apple.BluetoothAudioAgent "Negotiated Bitpool Max" 58
  defaults write com.apple.BluetoothAudioAgent "Negotiated Bitpool Min" 48
elif [ "$DISTRO" == "ubuntu" ]; then
  # Do something under Linux
  echo "Ok, Ubuntu..."

  $SUDO apt install build-essential automake cmake curl git heroky kubernetes-cli mariadb memcached postgresql rbenv redis ruby-build sqlite srcclr vim wget
fi

sleep_3min

echo "Creating ~/.nvmrc"
echo "10.16.3" > ~/.nvmrc
echo "Creating ~/.ruby_version"
echo "2.6.3" > ~/.ruby_version
echo "Configuring tmux color options"
echo "set -ga terminal-overrides \",xterm-256color:Tc\"" >> ~/.tmux.conf

# Configure custom git delta
git config --global core.pager "delta --dark"

# Fantastic Vimrc
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh

sleep_3min

# Oh My ZSH -- Lots of sugar here, iff we have zsh installed

[[ -f `which zsh` ]] && echo "Installing Oh My ZSH!" && sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

sleep_3min
pause

echo "Copying and activating pre-built .zshrc..."
[[ -f `which zsh` && -f "./zsh/.zshrc" ]] && cp ./zsh/.zshrc $HOME
[[ -f `which zsh` && -f "$HOME/.zshrc" ]] && . $HOME/.zshrc

# nvm -- Node Version Management
echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | $SHELL

# Install Node LTS, Update NPM, Install Basics
echo "Installing Node LTS..."
nvm install --lts
npm update npm -g
echo "Installing the global basics..."
npm i avn-nvm grunt grunt-cli gulp nodemon

# Install project node versions, etc etc
echo "Installing Node 10.15.3 for Nomad..."
nvm install 10.15.3
nvm use 10.15.3
npm update npm -g
echo "Installing the global basics..."
npm i -g avn-nvm grunt grunt-cli gulp nodemon


nvm use --lts

go get -u github.com/zendesk/z3nnew/...

git clone https://github.com/zendesk/northwoods_logo.git ~/.northwoods_logo
cd ~/.northwoods_logo && make && make install && cd ~
echo "northwoods_logo\n" >> ~/.zshrc
