# ==============================================================================
# LOCALE CONFIGURATION (Fix macOS ICU locale extensions in bash/subshells)
# ==============================================================================
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

# Homebrew — macOS (Apple Silicon / Intel) and Linux (Linuxbrew)
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv zsh)"
elif [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Dotfiles repo location — update this if you clone the repo elsewhere
export DOTFILES="$HOME/dotfiles"

# Github workspace root (your repos live in ~/Github/<owner>/)
export GITHUB_ROOT="$HOME/Github"

# Custom scripts (bin/ in the dotfiles repo, stow'd to ~/bin)
export PATH="$HOME/Github/_tools:$HOME/bin:$HOME/.local/bin:${PREFIX:-/data/data/com.termux/files/usr}/bin:$PATH"

# OrbStack — macOS only
[[ -f ~/.orbstack/shell/init.zsh ]] && source ~/.orbstack/shell/init.zsh
