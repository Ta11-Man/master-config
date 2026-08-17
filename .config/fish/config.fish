# config.fish

# ==============================================================================
# Interactive Mode Toggles
# ==============================================================================
function plain --description "Switch Starship, eza, and Tmux to ASCII mode"
    set -gx NERD_FONT 0
    set -gx STARSHIP_CONFIG "$HOME/.config/starship-plain.toml"
    setup_eza_aliases
    if test -n "$TMUX"
        tmux source-file ~/.tmux.conf >/dev/null 2>&1
    end
end

function fancy --description "Switch Starship, eza, and Tmux to Nerd Font mode"
    set -gx NERD_FONT 1
    set -gx STARSHIP_CONFIG "$HOME/.config/starship.toml"
    setup_eza_aliases
    if test -n "$TMUX"
        tmux source-file ~/.tmux.conf >/dev/null 2>&1
    end
end


# -----------------------------------------------------------------------------
# Smart Font Mode Detection
# -----------------------------------------------------------------------------
# If connecting from a modern emulator (Alacritty, WezTerm, Ghostty, Kitty, iTerm), default to fancymode
if test "$TERM_PROGRAM" = "ghostty" -o "$TERM_PROGRAM" = "WezTerm" -o "$TERM_PROGRAM" = "iTerm.app" -o "$TERM" = "alacritty" -o "$TERM" = "xterm-ghostty"
    fancy
else
    # Default to fancymode unless explicitly set to 0 in your environment
    if not set -q NERD_FONT
        fancy
    else if test "$NERD_FONT" = "1"
        fancy
    else
        plain
    end
end

# Cache the OS distro icon to /tmp once per session (for starship)
if not test -f /tmp/.os_glyph_$USER
    set -l os_id (awk -F= '$1=="ID"{gsub("\"", "", $2); print $2; exit}' /etc/os-release 2>/dev/null)
    switch "$os_id"
        case "ubuntu"
            echo -n "" > /tmp/.os_glyph_$USER
        case "arch"
            echo -n "󰣇" > /tmp/.os_glyph_$USER
        case "debian"
            echo -n "" > /tmp/.os_glyph_$USER
        case "fedora"
            echo -n "" > /tmp/.os_glyph_$USER
        case "rhel" "centos"
            echo -n "" > /tmp/.os_glyph_$USER
        case "alpine"
            echo -n "" > /tmp/.os_glyph_$USER
        case '*'
            echo -n "󰌽" > /tmp/.os_glyph_$USER
    end
end

# ==============================================================================
# Dynamic Eza / LS Configuration
# ==============================================================================
function setup_eza_aliases --description "Set eza aliases based on NERD_FONT state"
    if type -q eza
        set -l eza_common "--group-directories-first" "--git"

        if test "$NERD_FONT" = "0"
            # Plain Mode: Standard ASCII classification marks
            alias ls="eza $eza_common --no-icons --classify"
            alias ll="eza $eza_common --no-icons --classify -lh"
            alias la="eza $eza_common --no-icons --classify -a"
            alias lla="eza $eza_common --no-icons --classify -lah"
            alias tree="eza $eza_common --no-icons --classify --tree"
        else
            # Fancy Mode: Explicit value prevents eza from swallowing target directory paths
            alias ls="eza $eza_common --icons=auto"
            alias ll="eza $eza_common --icons=auto -lh"
            alias la="eza $eza_common --icons=auto -a"
            alias lla="eza $eza_common --icons=auto -lah"
            alias tree="eza $eza_common --icons=auto --tree"
        end
    else
        alias ls="ls --color=auto"
        alias ll="ls -lh --color=auto"
        alias la="ls -A --color=auto"
    end
end


# ==============================================================================
# SSH Hostname & Alias Pass-Through Hook
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
# Path Management (Fish Built-in Idempotent Paths)
# ==============================================================================
fish_add_path -g $HOME/.local/bin
fish_add_path -g $HOME/.cargo/bin
fish_add_path -g $HOME/.local/share/nvim/mason/bin

# ==============================================================================
# Interactive Session Initialization & Tooling
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