#!/usr/bin/env bash
set -euo pipefail

# Setup directories
BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}" "${HOME}/.config" "${HOME}/.local/share"
export PATH="${BIN_DIR}:${PATH}"

log() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
ok()  { printf "\033[1;32m[OK]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  FZF_ARCH="amd64"; EZA_ARCH="x86_64-unknown-linux-musl"; NVIM_ARCH="x86_64" ;;
  aarch64) FZF_ARCH="arm64"; EZA_ARCH="aarch64-unknown-linux-musl"; NVIM_ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# 1. Pull Git Submodules (Ensures Neovim & Nested Repos Are Populated)
# ==============================================================================
if [ -d "${SCRIPT_DIR}/.git" ]; then
  log "Initializing and updating git submodules..."
  cd "${SCRIPT_DIR}"
  git submodule update --init --recursive 2>/dev/null || true
fi

# ==============================================================================
# 2. User-Space Binary Provisioning (Zero Sudo)
# ==============================================================================

# Starship
if command -v starship >/dev/null 2>&1; then
  ok "Starship is already installed."
else
  log "Installing Starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir "${BIN_DIR}"
fi

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
  ok "Zoxide is already installed."
else
  log "Installing Zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | BIN_DIR="${BIN_DIR}" sh
fi

# Eza
if command -v eza >/dev/null 2>&1; then
  ok "Eza is already installed."
else
  log "Installing eza..."
  curl -sLo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_${EZA_ARCH}.tar.gz"
  tar -xzf /tmp/eza.tar.gz -C "${BIN_DIR}"
  chmod +x "${BIN_DIR}/eza"
  rm -f /tmp/eza.tar.gz
fi

# FZF
if command -v fzf >/dev/null 2>&1; then
  ok "fzf is already installed."
else
  log "Installing fzf..."
  FZF_URL=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep "browser_download_url.*linux_${FZF_ARCH}.tar.gz" | cut -d : -f 2,3 | tr -d '\" ')
  if [ -n "${FZF_URL}" ]; then
    curl -sLo /tmp/fzf.tar.gz "${FZF_URL}"
    tar -xzf /tmp/fzf.tar.gz -C "${BIN_DIR}"
    chmod +x "${BIN_DIR}/fzf"
    rm -f /tmp/fzf.tar.gz
  else
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 2>/dev/null || true
    ~/.fzf/install --bin
    ln -sf ~/.fzf/bin/fzf "${BIN_DIR}/fzf"
  fi
fi

# Neovim (Ensures a modern version is installed in ~/.local/)
if command -v nvim >/dev/null 2>&1 && [[ "$(nvim --version 2>/dev/null | head -n 1)" =~ v0\.(1[0-9]|[2-9][0-9]) ]]; then
  ok "Modern Neovim is already installed."
else
  log "Installing latest pre-built Neovim to ~/.local..."
  mkdir -p /tmp/nvim-install
  cd /tmp/nvim-install
  curl -sLo nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz"
  tar -xzf nvim.tar.gz
  rm -rf "${HOME}/.local/share/nvim-linux-${NVIM_ARCH}"
  mv "nvim-linux-${NVIM_ARCH}" "${HOME}/.local/share/"
  ln -sf "${HOME}/.local/share/nvim-linux-${NVIM_ARCH}/bin/nvim" "${BIN_DIR}/nvim"
  cd "${SCRIPT_DIR}"
  rm -rf /tmp/nvim-install
fi

# Fish Shell (Builds to ~/.local prefix only if missing)
if command -v fish >/dev/null 2>&1 && fish -c "exit 0" >/dev/null 2>&1; then
  ok "Fish is already installed."
else
  log "Installing/Building Fish Shell in user space..."
  mkdir -p /tmp/fish-build
  cd /tmp/fish-build
  curl -sLo fish.tar.xz "https://github.com/fish-shell/fish-shell/releases/download/3.7.1/fish-3.7.1.tar.xz"
  tar -xf fish.tar.xz
  cd fish-3.7.1
  cmake -DCMAKE_INSTALL_PREFIX="${HOME}/.local" -B build >/dev/null
  cmake --build build --target install >/dev/null
  cd "${SCRIPT_DIR}"
  rm -rf /tmp/fish-build
fi

# ==============================================================================
# 3. Symlink Configs
# ==============================================================================
log "Symlinking configuration files..."

# Root home dotfiles
ln -sf "${SCRIPT_DIR}/.bashrc" "${HOME}/.bashrc"
ln -sf "${SCRIPT_DIR}/.tmux.conf" "${HOME}/.tmux.conf"
[ -f "${SCRIPT_DIR}/.vimrc" ] && ln -sf "${SCRIPT_DIR}/.vimrc" "${HOME}/.vimrc"

# Directory configs
mkdir -p "${HOME}/.config/fish"
ln -sf "${SCRIPT_DIR}/.config/fish/config.fish" "${HOME}/.config/fish/config.fish"
ln -sfn "${SCRIPT_DIR}/.config/nvim" "${HOME}/.config/nvim"
ln -sfn "${SCRIPT_DIR}/.config/alacritty" "${HOME}/.config/alacritty"

# Starship configs
ln -sf "${SCRIPT_DIR}/.config/starship.toml" "${HOME}/.config/starship.toml"
ln -sf "${SCRIPT_DIR}/.config/starship-plain.toml" "${HOME}/.config/starship-plain.toml"

# Bat Theme setup
if [ -f "${SCRIPT_DIR}/.config/Swedish.tmTheme" ]; then
  mkdir -p "${HOME}/.config/bat/themes"
  ln -sf "${SCRIPT_DIR}/.config/Swedish.tmTheme" "${HOME}/.config/bat/themes/Swedish.tmTheme"
  if command -v bat >/dev/null 2>&1; then
    bat cache --build >/dev/null 2>&1 || true
  fi
fi

# ==============================================================================
# 4. Initialize Fish Path & Neovim Plugins
# ==============================================================================
if command -v fish >/dev/null 2>&1; then
  fish -c "fish_add_path -g ${BIN_DIR}" 2>/dev/null || true
fi

if command -v nvim >/dev/null 2>&1; then
  log "Syncing Neovim plugins..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
fi

ok "Deployment complete! Run 'exec fish' to start your session."