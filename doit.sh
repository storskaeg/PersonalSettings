#!/usr/bin/env bash

if [ "$(uname)" == "Darwin" ]; then
  # Do something under Mac OS X
  echo "Yep, we're on a mac"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  # Do something under Linux
  echo "Ok, Linux..."
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
