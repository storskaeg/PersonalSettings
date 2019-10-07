#!/usr/bin/env bash

SUDO=''
if (( $EUID != 0 )); then
  SUDO='sudo'
fi

# Determine OS platform
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
  echo "Yep, OSX..."
  echo "This script will run for a bit, but occasionally require your input."
  read -n 1 -s -r -p "Press any key to continue..."

  # Dev Tools
  $SUDO xcode-select --install
  # xcode-select -s /Applications/Xcode.app/Contents/Developer
  $SUDO xcodebuild -license accept

  # Homebrew
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  # The basics: basic tooling, standard datastores and caching, and helpers
  brew tap AdoptOpenJDK/openjdk
  brew update
  brew install curl dep git go heroku jfrog-cli-go kubernetes-cli mariadb memcached postgresql rbenv redis ruby-build sqlite srcclr vim wget
  brew cask install adoptopenjdk8
  brew cask install insomnia

  # Attempting to mitigate race condition by sleeping 3 minutes while homebrew completes, then waiting for the user to provide input
  sleep 180
  read -n 1 -s -r -p "Press any key to continue..."

  # Start the services
  # TODO: There's a race condition, here. We attempt to start the services before installation has completed.
  brew services start mariadb
  brew services start memcached
  brew services start postgresql
  brew services start redis
  brew services start sqlite

  # ZSH -- separated from the earlier installs so it can be commented out in needed
  brew install zsh
elif [ "$DISTRO" == "ubuntu" ]; then
  # Do something under Linux
  echo "Ok, Ubuntu..."

  $SUDO apt install build-essential automake cmake curl git heroky kubernetes-cli mariadb memcached postgresql rbenv redis ruby-build sqlite srcclr vim wget
fi

echo "10.16.3" > ~/.nvmrc
echo "2.6.3" > ~/.ruby_version

# Fantastic Vimrc
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh

# Oh My ZSH -- Lots of sugar here, iff we have zsh installed
[[ -f `which zsh` ]] && sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
[[ -f `which zsh` ]] && cp ./zsh/.zshrc $HOME

# nvm -- Node Version Management
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | $SHELL

# Install Node LTS, Update NPM, Install Basics
nvm install --lts
npm update npm -g
npm install avn-nvm grunt grunt-cli gulp

# Install project node versions, etc etc
nvm install 10.15.3
nvm use 10.15.3
npm update npm -g
npm install avn-nvm grunt grunt-cli gulp

nvm use --lts
