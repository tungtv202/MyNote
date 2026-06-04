#!/usr/bin/env zsh

# Shared shell helpers sourced by ~/.zshrc.
# Keep Linux-only commands in only_linux/linux_bash.sh.

if [[ -o interactive && -t 1 ]]; then
  # Load Powerlevel10k instant prompt only for interactive terminal sessions.
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi
fi

# Resolve this file's directory so sibling scripts can be sourced reliably.
MY_BASH_DIR="${${(%):-%x}:A:h}"

# Prefer personal scripts installed in ~/bin.
export PATH="$HOME/bin:$PATH"

# Load Oh My Zsh and interactive zsh plugins only in real terminal sessions.
if [[ -o interactive && -t 1 && -d "$HOME/.oh-my-zsh" ]]; then
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME="powerlevel10k/powerlevel10k"
  plugins=(git)
  source "$ZSH/oh-my-zsh.sh"

  [[ ! -f "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"

  [[ -f /opt/homebrew/etc/profile.d/autojump.sh ]] && source /opt/homebrew/etc/profile.d/autojump.sh
  [[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  [[ -f "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Java/Maven
# Load Java and Maven environment helpers.
source "$MY_BASH_DIR/java_maven_bash.sh"

# Docker
# Load Docker aliases and port helpers.
source "$MY_BASH_DIR/docker_bash.sh"

# Git
# Load personal Git shell aliases and functions.
source "$MY_BASH_DIR/git_alias.sh"
source "$MY_BASH_DIR/git_function.sh"

# Load Linux-only aliases/functions when this file is sourced on Linux.
if [[ "$(uname -s)" != "Darwin" ]]; then
  source "$MY_BASH_DIR/only_linux/linux_bash.sh"
fi

# AWS
# Disabled because this workflow is not currently used.
# Example when restored: s3_upload /path/to/file
# alias s3_upload="bash $S3_UPLOAD_SHELL_PATH"

# Print the current directory and copy it to the clipboard.
# Example: pwc
pwc() {
  pwd
  if command -v pbcopy >/dev/null 2>&1; then
    pwd | pbcopy
  elif command -v xclip >/dev/null 2>&1; then
    pwd | xclip -selection clipboard
  elif command -v wl-copy >/dev/null 2>&1; then
    pwd | wl-copy
  else
    echo "pwc: clipboard command not found" >&2
    return 1
  fi
}

# Create a directory and enter it.
# Example: mkcdir /tmp/demo
mkcdir() {
  mkdir -p -- "$1" && cd -P -- "$1"
}
