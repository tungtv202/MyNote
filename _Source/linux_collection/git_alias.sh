#!/usr/bin/env zsh

# Git config aliases from ~/.gitconfig, plus older aliases kept from this note.
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

# Custom git helpers from ~/.zshrc.
gitpr() {
    if [ -z "$1" ]; then
        echo "Usage: gitpr <pull-request-number>"
        return 1
    fi
    git fetch origin pull/"$1"/head:pr-"$1"
    git checkout pr-"$1"
}

# Recreate local main/master from the current branch, then force push it to remote "tung".
gmt() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "gmt: not inside a git repository"
    return 1
  fi

  local current_branch source_ref target_branch
  current_branch="$(git branch --show-current)"
  if [[ -z "$current_branch" ]]; then
    echo "gmt: current HEAD is detached; checkout a branch first"
    return 1
  fi

  if ! git remote get-url origin >/dev/null 2>&1; then
    echo "gmt: remote 'origin' not found"
    return 1
  fi

  if ! git remote get-url tung >/dev/null 2>&1; then
    echo "gmt: remote 'tung' not found"
    return 1
  fi

  git fetch --prune origin || return 1

  target_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"
  target_branch="${target_branch#origin/}"
  if [[ "$target_branch" != "main" && "$target_branch" != "master" ]]; then
    if git show-ref --verify --quiet refs/remotes/origin/main; then
      target_branch="main"
    elif git show-ref --verify --quiet refs/remotes/origin/master; then
      target_branch="master"
    else
      echo "gmt: origin has neither main nor master"
      return 1
    fi
  fi

  source_ref="$(git rev-parse --verify HEAD)" || return 1
  echo "gmt: recreating local '$target_branch' from '$current_branch'"

  if [[ "$current_branch" != "$target_branch" ]] && git show-ref --verify --quiet "refs/heads/$target_branch"; then
    git branch -D "$target_branch" || return 1
  fi

  git switch -C "$target_branch" "$source_ref" || return 1
  git push --force tung "$target_branch:$target_branch"
}

# List local git branches by latest commit time.
gitbrs() {
  local limit="${1:-8}"

  case "$limit" in
    ''|*[!0-9]*)
      echo "Usage: gitbrs [number-of-branches]"
      return 1
      ;;
  esac

  if (( limit < 1 )); then
    echo "Usage: gitbrs [number-of-branches]"
    return 1
  fi

  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "gitbrs: not inside a git repository"
    return 1
  fi

  {
    printf 'BRANCH\tLAST COMMIT\tHASH\tMESSAGE\n'
    git for-each-ref \
      --count="$limit" \
      --sort=-committerdate \
      --format='%(refname:short)%09%(committerdate:format:%Y-%m-%d %H:%M)%09%(objectname:short)%09%(subject)' \
      refs/heads
  } |
    column -t -s $'\t' |
    awk '
      BEGIN {
        split("91 92 95 93 96 94 31 32 35 33 36 34", hash_palette, " ")
        hash_palette_count = 12
      }
      NR == 1 {
        printf "\033[1m%s\033[0m\n", $0
        next
      }
      {
        hash = $4
        if (!(hash in color_by_hash)) {
          color_by_hash[hash] = hash_palette[(hash_count % hash_palette_count) + 1]
          hash_count++
        }

        hash_start = 1
        for (i = 1; i < 4; i++) {
          hash_start += length($i)
          while (substr($0, hash_start, 1) ~ /[[:space:]]/) {
            hash_start++
          }
        }

        line = substr($0, 1, hash_start - 1) "\033[" color_by_hash[hash] "m" hash "\033[0m" substr($0, hash_start + length(hash))
        print line
      }
    '
}

# List local branches and SSH remote branches by latest commit time.
gitbrsAll() {
  local limit="${1:-10}"

  case "$limit" in
    ''|*[!0-9]*)
      echo "Usage: gitbrsAll [number-of-branches]"
      return 1
      ;;
  esac

  if (( limit < 1 )); then
    echo "Usage: gitbrsAll [number-of-branches]"
    return 1
  fi

  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "gitbrsAll: not inside a git repository"
    return 1
  fi

  local -A ssh_remotes
  local remote url
  while IFS=$'\t' read -r remote url; do
    case "$url" in
      git@*:*|ssh://*) ssh_remotes[$remote]=1 ;;
    esac
  done < <(git remote -v | awk '$3 == "(fetch)" { print $1 "\t" $2 }')

  local ref commit_time commit_hash message branch rest shown=0
  {
    printf 'REMOTE\tBRANCH\tLAST COMMIT\tHASH\tMESSAGE\n'
    while IFS=$'\t' read -r ref commit_time commit_hash message; do
      case "$ref" in
        refs/heads/*)
          remote="local"
          branch="${ref#refs/heads/}"
          ;;
        refs/remotes/*/HEAD)
          continue
          ;;
        refs/remotes/*)
          rest="${ref#refs/remotes/}"
          remote="${rest%%/*}"
          [[ -n "${ssh_remotes[$remote]}" ]] || continue
          branch="${rest#*/}"
          ;;
        *)
          continue
          ;;
      esac

      printf '%s\t%s\t%s\t%s\t%s\n' "$remote" "$branch" "$commit_time" "$commit_hash" "$message"
      (( shown++ ))
      (( shown >= limit )) && break
    done < <(
      git for-each-ref \
        --sort=-committerdate \
        --format='%(refname)%09%(committerdate:format:%Y-%m-%d %H:%M)%09%(objectname:short)%09%(subject)' \
        refs/heads refs/remotes
    )
  } |
    column -t -s $'\t' |
    awk '
      BEGIN {
        split("36 32 35 33 34 31 96 92 95 93 94 91", remote_palette, " ")
        split("91 92 95 93 96 94 31 32 35 33 36 34", hash_palette, " ")
        remote_palette_count = 12
        hash_palette_count = 12
      }
      NR == 1 {
        printf "\033[1m%s\033[0m\n", $0
        next
      }
      {
        remote = $1
        hash = $5
        if (!(remote in color_by_remote)) {
          color_by_remote[remote] = remote_palette[(remote_count % remote_palette_count) + 1]
          remote_count++
        }
        if (!(hash in color_by_hash)) {
          color_by_hash[hash] = hash_palette[(hash_count % hash_palette_count) + 1]
          hash_count++
        }

        hash_start = 1
        for (i = 1; i < 5; i++) {
          hash_start += length($i)
          while (substr($0, hash_start, 1) ~ /[[:space:]]/) {
            hash_start++
          }
        }

        line = substr($0, 1, hash_start - 1) "\033[" color_by_hash[hash] "m" hash "\033[0m" substr($0, hash_start + length(hash))
        line = "\033[" color_by_remote[remote] "m" remote "\033[0m" substr(line, length(remote) + 1)
        print line
      }
    '
}
