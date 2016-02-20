#!/usr/bin/env bash

if [ "$(uname)" == "Darwin" ]; then
  # Do something under Mac OS X
  echo "Yep, we're on a mac"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  # Do something under Linux
  echo "Ok, Linux..."
fi
