# if interactive, return without running .bashrc
# this allows sftp to run
[[ $- == *i* ]] || return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias py='python'

. "$HOME/.cargo/env"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# -----------------------------------------------------------------------------
# Terminal Capability & Font Detection
# -----------------------------------------------------------------------------
# Detect if running via SSH, Linux virtual console (TTY), or basic terminal
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ "$TERM" = "linux" ] || [ "$TERM" = "dumb" ]; then
    export NERD_FONT=0
    export STARSHIP_CONFIG="$HOME/.config/starship-plain.toml"
else
    export NERD_FONT=1
    export STARSHIP_CONFIG="$HOME/.config/starship.toml"
fi

alias plainmode='export NERD_FONT=0; export STARSHIP_CONFIG="$HOME/.config/starship-plain.toml"; tmux source-file ~/.tmux.conf 2>/dev/null'
alias richmode='export NERD_FONT=1; export STARSHIP_CONFIG="$HOME/.config/starship.toml"; tmux source-file ~/.tmux.conf 2>/dev/null'

eval "$(starship init bash)" # or zsh

# -----------------------------------------------------------------------------
# Dynamic eza / ls Setup
# -----------------------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
    # Base arguments for clean output
    EZA_COMMON="--group-directories-first --git"

    set_ls_aliases() {
        if [ "${NERD_FONT:-1}" = "0" ]; then
            # Plain Mode:
            # --classify adds standard ASCII markers (/ for dirs, * for executables, @ for symlinks)
            # --no-icons ensures no broken Unicode box characters appear
            alias ls="eza ${EZA_COMMON} --no-icons --classify"
            alias ll="eza ${EZA_COMMON} --no-icons --classify -lh"
            alias la="eza ${EZA_COMMON} --no-icons --classify -a"
            alias lla="eza ${EZA_COMMON} --no-icons --classify -lah"
            alias tree="eza ${EZA_COMMON} --no-icons --classify --tree"
        else
            # Rich Mode: Full Nerd Font icons enabled
            alias ls="eza ${EZA_COMMON} --icons"
            alias ll="eza ${EZA_COMMON} --icons -lh"
            alias la="eza ${EZA_COMMON} --icons -a"
            alias lla="eza ${EZA_COMMON} --icons -lah"
            alias tree="eza ${EZA_COMMON} --icons --tree"
        fi
    }
else
    # Fallback to standard coreutils ls if eza is not installed
    alias ls="ls --color=auto"
    alias ll="ls -lh --color=auto"
    alias la="ls -A --color=auto"
fi

# -----------------------------------------------------------------------------
# Auto-launch Fish in User Space
# -----------------------------------------------------------------------------
export PATH="${HOME}/.local/bin:${PATH}"

# If interactive, not already in fish, and fish exists in ~/.local/bin:
if [[ $- == *i* ]] && [ -z "$FISH_VERSION" ] && command -v fish >/dev/null 2>&1; then
    exec fish
fi