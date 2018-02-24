#!/usr/bin/env bash

export LANG="en_US.UTF-8"
export LC_ALL="$LANG"
export DEFAULT_USER=dmitmel

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR="rmate"
else
  export EDITOR="code"
fi

export CLICOLOR=1

export SDKMAN_DIR="$HOME/.sdkman"
