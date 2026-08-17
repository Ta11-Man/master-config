#!/usr/bin/env bash
set -euo pipefail

# Setup user binary path
BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"
mkdir -p "${HOME}/.config"
export PATH="${BIN_DIR}:${PATH}"

log() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
ok()  { printf "\033[1;32m[OK]\033[0m %s\n" "$*"; }

# Detect architecture (x86_64 or aarch64)
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARCH_ALT="x86_64"; ARCH_GNU="x86_64-unknown-linux-musl" ;;
  aarch64) ARCH_ALT="aarch64"; ARCH_GNU="aarch64-unknown-linux-musl" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# ------------------------------------------------------------------------------
# 1. Download User-Space Binaries (No Root / No Sudo Required)
# ------------------------------------------------------------------------------

# Starship
if ! command -v starship >/dev/null 2>&1; then
  log "Installing Starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir "${BIN_DIR}"
fi

# Neovim (Pre-built AppImage or static tarball)
if ! command -v nvim >/dev/null 2>&1; then
  log "Installing Neovim..."
  curl -Lo "${BIN_DIR}/nvim" "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.appimage" 2>/dev/null || \
  curl -Lo "${BIN_DIR}/nvim" "https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
  chmod +x "${BIN_DIR}/nvim"
fi

# Fish Shell (Static AppImage / Binary)
if ! command -v fish >/dev/null 2>&1; then
  log "Installing Fish Shell..."
  # Download static fish AppImage or compile-free binary release
  curl -Lo "${BIN_DIR}/fish" "https://github.com/freedesktop/fish-static/releases/latest/download/fish.static.${ARCH}" 2>/dev/null || true
  if [ -f "${BIN_DIR}/fish" ]; then
    chmod +x "${BIN_DIR}/fish"
  fi
fi

# Zoxide
if ! command -v zoxide >/dev/null 2>&1; then
  log "Installing Zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | BIN_DIR="${BIN_DIR}" sh
fi

# FZF
if ! command -v fzf >/dev/null 2>&1; then
  log "Installing fzf..."
  curl -Lo /tmp/fzf.tar.gz "https://github.com/junegunn/fzf/releases/latest/download/fzf-0.54.3-linux_amd64.tar.gz"
  tar -xzf /tmp/fzf.tar.gz -C "${BIN_DIR}"
  rm -f /tmp/fzf.tar.gz
fi

# ------------------------------------------------------------------------------
# 2. Stow / Symlink Dotfiles
# ------------------------------------------------------------------------------
log "Linking dotfiles..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v stow >/dev/null 2>&1; then
  stow -d "${SCRIPT_DIR}" -t "${HOME}" config shell --adopt
else
  # Native symlink fallback if Stow is not installed on the remote machine
  log "GNU Stow not found; using manual symlink fallback..."
  ln -sf "${SCRIPT_DIR}/shell/.bashrc" "${HOME}/.bashrc"
  ln -sf "${SCRIPT_DIR}/shell/.tmux.conf" "${HOME}/.tmux.conf"
  ln -sf "${SCRIPT_DIR}/shell/.vimrc" "${HOME}/.vimrc"

  # Link nested configs
  mkdir -p "${HOME}/.config/fish" "${HOME}/.config/nvim" "${HOME}/.config/alacritty"
  ln -sf "${SCRIPT_DIR}/config/.config/fish/config.fish" "${HOME}/.config/fish/config.fish"
  ln -sf "${SCRIPT_DIR}/config/.config/starship.toml" "${HOME}/.config/starship.toml"
  ln -sf "${SCRIPT_DIR}/config/.config/starship-plain.toml" "${HOME}/.config/starship-plain.toml"
  ln -sf "${SCRIPT_DIR}/config/.config/nvim" "${HOME}/.config/nvim"
fi

ok "Environment bootstrapped successfully!"

# ------------------------------------------------------------------------------
# 3. Provision Neovim Headless
# ------------------------------------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
  log "Syncing Neovim plugins..."
  nvim --headless "+Lazy! sync" +qa || true
fi