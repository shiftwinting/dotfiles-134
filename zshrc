#!/usr/bin/env zsh

if [[ -n "$DOTFILES_PATH" ]]; then
  for script in oh-my-zsh aliases widgets theme; do
    source "$DOTFILES_PATH/lib/$script.zsh"
    source_if_exists "$DOTFILES_PATH/custom/$script.zsh"
  done

  run_before rbenv 'eval "$(rbenv init -)"'
  run_before sdk 'source_if_exists "$SDKMAN_DIR/bin/sdkman-init.sh"'
fi
