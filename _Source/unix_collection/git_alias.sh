#!/usr/bin/env zsh

# Personal Git shell aliases for interactive usage.

# Pull the current branch and update submodules.
# Example: gitupdate
alias gitupdate="git pull origin HEAD && git submodule update"

# Reset tracked files, clean untracked files, and reset submodules.
# Example: gitreset
alias gitreset="git reset --hard && git clean -fd && git submodule update --init && git submodule foreach git reset --hard"

# Reinitialize submodules and reset their working trees.
# Example: gitrsmd
alias gitrsmd="git submodule update --init && git submodule foreach git reset --hard"

# Show a compact graph of all refs.
# Example: gitlog
alias gitlog="git log --graph --oneline --all"

# Install Git config aliases from ~/.gitconfig, plus older aliases kept from this note.
# Example: install_git_config_aliases
install_git_config_aliases() {
  git config --global alias.co checkout
  git config --global alias.br branch
  git config --global alias.ci commit
  git config --global alias.st status
  git config --global alias.rss 'reset --soft HEAD^1'
  git config --global alias.rsh 'reset --hard'
  git config --global alias.stp 'stash pop'
  git config --global alias.cl 'clean -fd'
  git config --global alias.f 'fetch'
  git config --global alias.amne 'commit --amend --no-edit --date'
  git config --global alias.rbi 'rebase -i origin/main'
  git config --global alias.rbmo 'rebase -i origin/master'
  git config --global alias.rbm 'rebase -i origin/master'
  git config --global alias.fa 'fetch --all --prune --tags'
  git config --global alias.fao 'fetch --prune --tags origin'
  git config --global alias.gom '!f() { git fetch --prune origin; if git show-ref --verify --quiet refs/remotes/origin/master; then b=master; elif git show-ref --verify --quiet refs/remotes/origin/main; then b=main; else echo "Không thấy origin/master hoặc origin/main"; return 1; fi; git switch "$b" 2>/dev/null || git switch --track "origin/$b"; git reset --hard "origin/$b"; }; f'
}

if [[ "${ZSH_EVAL_CONTEXT:-}" != *:file ]]; then
  install_git_config_aliases
fi
