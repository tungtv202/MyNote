#!/usr/bin/env bash
set -euo pipefail

# Bootstrap common tools for a fresh Ubuntu-like desktop.
# Keep personal shell aliases/functions in ../1_my_bash.sh.

require_apt() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "for_new_os: apt-get not found; this script expects Ubuntu/Debian." >&2
    exit 1
  fi
}

apt_install() {
  sudo apt-get install -y "$@"
}

install_base_cli() {
  apt_install \
    ca-certificates \
    curl \
    git \
    gnupg \
    software-properties-common \
    zsh
}

install_oh_my_zsh() {
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    local install_script
    install_script="$(mktemp)"
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$install_script"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$install_script" --unattended
    rm -f "$install_script"
  fi

  local plugin_dir="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
  if [[ ! -d "$plugin_dir" ]]; then
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$plugin_dir"
  fi

  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ -n "$zsh_path" && "${SHELL:-}" != "$zsh_path" ]]; then
    chsh -s "$zsh_path" || echo "for_new_os: chsh failed; change shell manually with: chsh -s $zsh_path" >&2
  fi
}

install_desktop_tools() {
  apt_install \
    bluez \
    bluez-tools \
    blueman \
    imwheel \
    keepassxc \
    terminator
}

install_monitoring_tools() {
  apt_install \
    lm-sensors \
    psensor

  echo "Run 'sudo sensors-detect' manually if hardware sensors are missing."
}

install_vietnamese_input() {
  sudo add-apt-repository -y ppa:bamboo-engine/ibus-bamboo
  sudo apt-get update
  apt_install --install-recommends ibus ibus-bamboo

  ibus restart || true
  env DCONF_PROFILE=ibus dconf write /desktop/ibus/general/preload-engines "['BambooUs', 'Bamboo']" || true
  gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'Bamboo')]" || true
}

main() {
  require_apt

  sudo apt-get update
  install_base_cli
  install_oh_my_zsh
  install_desktop_tools
  install_monitoring_tools
  install_vietnamese_input
}

main "$@"
