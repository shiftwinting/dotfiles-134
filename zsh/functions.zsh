#!/usr/bin/env zsh

count() { print -r -- "$#"; }

bytecount() { wc -c "$@" | numfmt --to=iec-i --suffix=B; }

mkcd() { mkdir -p "$@" && cd "${@[-1]}"; }

viscd() {
  setopt local_options err_return
  local temp_file chosen_dir
  temp_file="$(mktemp -t ranger_cd.XXXXXXXXXX)"
  {
    ranger --choosedir="$temp_file" -- "${@:-$PWD}"
    if chosen_dir="$(<"$temp_file")" && [[ -n "$chosen_dir" && "$chosen_dir" != "$PWD" ]]; then
      cd -- "$chosen_dir"
    fi
  } always {
    rm -f -- "$temp_file"
  }
}

# Checks if a word can be meaningfully executed as a command (aliases,
# functions and builtins also count).
command_exists() { whence -- "$@" &>/dev/null; }
# Searches the command binary in PATH.
command_locate() { whence -p -- "$@"; }

lazy_load() {
  local command="$1"
  local init_command="$2"

  eval "$command() {
    unfunction $command
    $init_command
    $command \$@
  }"
}

if (( ! _is_macos )); then
  if (( _is_android )); then
    open_cmd='termux-open'
  elif command_exists xdg-open; then
    open_cmd='nohup xdg-open &> /dev/null'
  else
    open_cmd='print >&2 -r -- "open: Platform $OSTYPE is not supported"; return 1'
  fi
  eval "open(){local f; for f in \"\$@\"; do $open_cmd \"\$f\"; done;}"
  unset open_cmd
fi

if (( _is_macos )); then
  copy_cmd='pbcopy' paste_cmd='pbpaste'
elif command_exists xclip; then
  copy_cmd='xclip -in -selection clipboard' paste_cmd='xclip -out -selection clipboard'
elif command_exists xsel; then
  copy_cmd='xsel --clipboard --input' paste_cmd='xsel --clipboard --output'
elif command_exists termux-clipboard-set && command_exists termux-clipboard-get; then
  copy_cmd='termux-clipboard-set' paste_cmd='termux-clipboard-get'
else
  error_msg='Platform $OSTYPE is not supported'
  copy_cmd='print >&2 -r -- "clipcopy: '"$error_msg"'"; return 1'
  paste_cmd='print >&2 -r -- "clippaste: '"$error_msg"'"; return 1'
  unset error_msg
fi
eval "clipcopy() { $copy_cmd; }; clippaste() { $paste_cmd; }"
unset copy_cmd paste_cmd

# for compatibility with Oh My Zsh plugins
# Source: https://github.com/ohmyzsh/ohmyzsh/blob/5911aea46c71a2bcc6e7c92e5bebebf77b962233/lib/git.zsh#L58-L71
git_current_branch() {
  if [[ "$(command git rev-parse --is-inside-work-tree)" != true ]]; then
    return 1
  fi

  local ref
  ref="$(
    command git symbolic-ref --quiet HEAD 2> /dev/null ||
    command git rev-parse --short HEAD 2> /dev/null
  )" || return
  print -r -- "${ref#refs/heads/}"
}

declare -A date_formats=(
  iso       '%Y-%m-%dT%H:%M:%SZ'
  normal    '%Y-%m-%d %H:%M:%S'
  compact   '%Y%m%d%H%M%S'
  only-date '%Y-%m-%d'
  only-time '%H:%M:%S'
  timestamp '%s'
)

for format_name format in "${(kv)date_formats[@]}"; do
  eval "date-fmt-${format_name}() { date +${(q)format} \"\$@\"; }"
done; unset format_name format

unset date_formats

if (( _is_linux )) && command_exists swapoff && command_exists swapon; then
  deswap() { sudo sh -c 'swapoff --all && swapon --all'; }
fi

# Taken from <https://vi.stackexchange.com/a/7810/34615>
sudoedit() {
  SUDO_COMMAND="sudoedit $@" command sudoedit "$@"
}
alias sudoe="sudoedit"
alias sue="sudoedit"

# This idea was taken from <https://github.com/ohmyzsh/ohmyzsh/blob/706b2f3765d41bee2853b17724888d1a3f6f00d9/plugins/last-working-dir/last-working-dir.plugin.zsh>
SYNC_WORKING_DIR_STORAGE="${ZSH_CACHE_DIR}/last-working-dir"

autoload -Uz add-zsh-hook
add-zsh-hook chpwd sync_working_dir_chpwd_hook
sync_working_dir_chpwd_hook() {
  if [[ "$ZSH_SUBSHELL" == 0 ]]; then
    sync_working_dir_save
  fi
}

sync_working_dir_save() {
  pwd >| "$SYNC_WORKING_DIR_STORAGE"
}

sync_working_dir_load() {
  local dir
  if dir="$(<"$SYNC_WORKING_DIR_STORAGE")" 2>/dev/null && [[ -n "$dir" ]]; then
    cd -- "$dir"
  fi
}
alias cds="sync_working_dir_load"

discord-avatar() {
  setopt local_options err_return
  if (( $# != 1 )); then
    print >&2 "Usage: $0 [user_snowflake]"
    return 1
  fi
  local avatar_url
  avatar_url="$(discord-whois --image-size 4096 --get 'Avatar' "$1")"
  open "$avatar_url"
}

read_line() {
  IFS= read -r -- "$@"
}

print_lines() {
  print -rC1 -- "$@"
}

print_null() {
  print -rNC1 -- "$@"
}
