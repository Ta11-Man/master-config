# ==============================================================================
# 1. Terminal Font & Environment Detection
# ==============================================================================
if test -n "$SSH_CONNECTION" -o -n "$SSH_CLIENT" -o "$TERM" = "linux" -o "$TERM" = "dumb"
    set -gx NERD_FONT 0
    set -gx STARSHIP_CONFIG "$HOME/.config/starship-plain.toml"
else
    set -gx NERD_FONT 1
    set -gx STARSHIP_CONFIG "$HOME/.config/starship.toml"
end

# ==============================================================================
# 2. Dynamic Eza / LS Configuration
# ==============================================================================
function setup_eza_aliases --description "Set eza aliases based on NERD_FONT state"
    if type -q eza
        set -l eza_common "--group-directories-first" "--git"

        if test "$NERD_FONT" = "0"
            # Plain Mode: Standard ASCII markers (/, *, @), zero PUA icons
            alias ls="eza $eza_common --no-icons --classify"
            alias ll="eza $eza_common --no-icons --classify -lh"
            alias la="eza $eza_common --no-icons --classify -a"
            alias lla="eza $eza_common --no-icons --classify -lah"
            alias tree="eza $eza_common --no-icons --classify --tree"
        else
            # Rich Mode: Full Nerd Font icons
            alias ls="eza $eza_common --icons"
            alias ll="eza $eza_common --icons -lh"
            alias la="eza $eza_common --icons -a"
            alias lla="eza $eza_common --icons -a"
            alias lla="eza $eza_common --icons -lah"
            alias tree="eza $eza_common --icons --tree"
        end
    else
        alias ls="ls --color=auto"
        alias ll="ls -lh --color=auto"
        alias la="ls -A --color=auto"
    end
end

# ==============================================================================
# 3. Interactive Mode Toggles
# ==============================================================================
function plainmode --description "Switch Starship, eza, and Tmux to ASCII mode"
    set -gx NERD_FONT 0
    set -gx STARSHIP_CONFIG "$HOME/.config/starship-plain.toml"
    setup_eza_aliases
    if test -n "$TMUX"
        tmux source-file ~/.tmux.conf >/dev/null 2>&1
    end
end

function richmode --description "Switch Starship, eza, and Tmux to Nerd Font mode"
    set -gx NERD_FONT 1
    set -gx STARSHIP_CONFIG "$HOME/.config/starship.toml"
    setup_eza_aliases
    if test -n "$TMUX"
        tmux source-file ~/.tmux.conf >/dev/null 2>&1
    end
end

# ==============================================================================
# 4. SSH Hostname & Alias Pass-Through Hook
# ==============================================================================
function ssh --wraps=ssh --description "Wrap ssh to forward connection alias"
    set -l target "$argv[1]"
    for arg in $argv
        if not string match -q -- "-*" $arg
            set target $arg
            break
        end
    end

    env LC_SSH_ALIAS="$target" command ssh -o "SendEnv LC_SSH_ALIAS" $argv
end

# Windows interop helper
function tshark --wraps=tshark
    /mnt/c/Program\ Files/Wireshark/tshark.exe $argv
end

# Custom Greeting
function fish_greeting
    echo "Welcome to Gabe's fish in Arch!"
    echo "The time is "(set_color yellow)(date +%T)(set_color normal)" and this machine is "(set_color cyan)$hostname(set_color normal)
end

# ==============================================================================
# 5. Path Management (Fish Built-in Idempotent Paths)
# ==============================================================================
fish_add_path -g $HOME/.local/bin
fish_add_path -g $HOME/.cargo/bin
fish_add_path -g $HOME/.local/share/nvim/mason/bin

# ==============================================================================
# 6. Interactive Session Initialization & Tooling
# ==============================================================================
if status is-interactive
    # Setup initial LS alias state
    setup_eza_aliases

    # Shell Integration initializations (single run)
    type -q starship; and starship init fish | source
    type -q zoxide; and zoxide init fish | source
    type -q fzf; and fzf --fish | source

    # Core Environment Variables
    set -gx EDITOR nvim
    set -gx VISUAL nvim

    # Bat Pager & Theme Setup
    if type -q bat
        set -gx BAT_THEME "Swedish"
        set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
        set -gx MANROFFOPT "-c"
        alias cat="bat --paging=never --style=plain"
        alias catp="bat"
    else
        set -gx MANPAGER "nvim +Man!"
    end

    # FZF Defaults (respects .gitignore via fd)
    if type -q fd
        set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix --hidden --exclude .git'
        set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
        set -gx FZF_ALT_C_COMMAND 'fd --type d --strip-cwd-prefix --hidden --exclude .git'
        alias find="fd"
    end

    if type -q rg
        alias grep="rg"
    end

    set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --inline-info"
end