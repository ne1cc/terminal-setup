# Clean UTF-8 locale configuration (prevents macOS ICU format warnings)
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

# Inherit PATH
export PATH="/root/.local/bin:/opt/homebrew/bin:/usr/local/bin:/home/linuxbrew/.linuxbrew/bin:$HOME/bin:$HOME/.local/bin:$PATH"

# agy / agyy alias
alias agyy='agy --dangerously-skip-permissions'

