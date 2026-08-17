#!/usr/bin/env bash
set -euo pipefail

# Setup user binary path
BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"
mkdir -p "${HOME}/.config"
export PATH="${BIN_DIR}:${PATH}"

log() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
ok()  { printf "\033[1;32m[OK]\033[0m %s\n" "$*"; }

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  FZF_ARCH="amd64"; NVIM_ARCH="x86_64" ;;
  aarch64) FZF_ARCH="arm64"; NVIM_ARCH="arm64" ;;
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

# Neovim (AppImage or tarball fallback)
if ! command -v nvim >/dev/null 2>&1; then
  log "Installing Neovim..."
  curl -Lo "${BIN_DIR}/nvim" "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.appimage" 2>/dev/null || true
  if [ -f "${BIN_DIR}/nvim" ]; then
    chmod +x "${BIN_DIR}/nvim"
  fi
fi

# Fish Shell (Official Static AppImage / Bin)
if ! command -v fish >/dev/null 2>&1; then
  log "Installing Fish Shell..."
  # Download static fish binary directly
  curl -Lo "${BIN_DIR}/fish" "https://github.com/fish-shell/fish-shell/releases/latest/download/fish" 2>/dev/null || true
  if [ -s "${BIN_DIR}/fish" ]; then
    chmod +x "${BIN_DIR}/fish"
  else
    # Fallback to AppImage if raw binary is unavailable
    curl -Lo "${BIN_DIR}/fish" "https://github.com/fish-shell/fish-shell/releases/latest/download/fish.appimage" 2>/dev/null || true
    [ -f "${BIN_DIR}/fish" ] && chmod +x "${BIN_DIR}/fish"
  fi
fi

# Zoxide
if ! command -v zoxide >/dev/null 2>&1; then
  log "Installing Zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | BIN_DIR="${BIN_DIR}" sh
fi

# FZF (Official git release script - avoids 404 tarball URL breaks)
if ! command -v fzf >/dev/null 2>&1; then
  log "Installing fzf..."
  # Resolves latest tag dynamically from github redirects
  FZF_URL=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep "browser_download_url.*linux_${FZF_ARCH}.tar.gz" | cut -d : -f 2,3 | tr -d '\" ')
  if [ -n "${FZF_URL}" ]; then
    curl -sLo /tmp/fzf.tar.gz "${FZF_URL}"
    tar -xzf /tmp/fzf.tar.gz -C "${BIN_DIR}"
    chmod +x "${BIN_DIR}/fzf"
    rm -f /tmp/fzf.tar.gz
  else
    # Fallback via git clone installer
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 2>/dev/null || true
    ~/.fzf/install --bin
    ln -sf ~/.fzf/bin/fzf "${BIN_DIR}/fzf"
  fi
fi

# ------------------------------------------------------------------------------
# 2. Stow / Symlink Dotfiles
# ------------------------------------------------------------------------------
log "Linking dotfiles..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v stow >/dev/null 2>&1; then
  stow -d "${SCRIPT_DIR}" -t "${HOME}" config shell --adopt
else
  log "Using symlink fallback..."
  [ -f "${SCRIPT_DIR}/shell/.bashrc" ] && ln -sf "${SCRIPT_DIR}/shell/.bashrc" "${HOME}/.bashrc"
  [ -f "${SCRIPT_DIR}/shell/.tmux.conf" ] && ln -sf "${SCRIPT_DIR}/shell/.tmux.conf" "${HOME}/.tmux.conf"
  [ -f "${SCRIPT_DIR}/shell/.vimrc" ] && ln -sf "${SCRIPT_DIR}/shell/.vimrc" "${HOME}/.vimrc"

  mkdir -p "${HOME}/.config/fish" "${HOME}/.config/nvim" "${HOME}/.config/alacritty"
  [ -f "${SCRIPT_DIR}/config/.config/fish/config.fish" ] && ln -sf "${SCRIPT_DIR}/config/.config/fish/config.fish" "${HOME}/.config/fish/config.fish"
  [ -f "${SCRIPT_DIR}/config/.config/starship.toml" ] && ln -sf "${SCRIPT_DIR}/config/.config/starship.toml" "${HOME}/.config/starship.toml"
  [ -f "${SCRIPT_DIR}/config/.config/starship-plain.toml" ] && ln -sf "${SCRIPT_DIR}/config/.config/starship-plain.toml" "${HOME}/.config/starship-plain.toml"
  [ -d "${SCRIPT_DIR}/config/.config/nvim" ] && ln -sf "${SCRIPT_DIR}/config/.config/nvim" "${HOME}/.config/nvim"
fi

ok "Environment bootstrapped successfully!"

# ------------------------------------------------------------------------------
# 3. Headless Neovim Sync
# ------------------------------------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
  log "Syncing Neovim plugins..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
fi