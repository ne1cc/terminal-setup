# ==============================================================================
# 1. POWERLEVEL10K INSTANT PROMPT
# ==============================================================================
# Must be first — before any output or prompts.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Detect WL (Windows Subsystem for Linux)
if grep -qi microsoft /proc/version 2>/dev/null; then
    export IS_WSL=1
fi

# Locale sanitization (fixes macOS ICU format warnings in bash / tools)
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

# ==============================================================================
# 2. OH MY ZSH INITIALIZATION & CONFIGURATION
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"

# Powerlevel10k — OMZ loads this from custom/themes/powerlevel10k/
ZSH_THEME="powerlevel10k/powerlevel10k"

# Disable auto-setting terminal title (tmux owns this)
DISABLE_AUTO_TITLE="true"

# Fleet Multi-Agent Orchestrator Completions
fpath=("${XDG_CONFIG_HOME:-$HOME/.config}/fleet/completions" $fpath)

plugins=(git)

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Starship Prompt Initialization (fallback/alternative)
if command -v starship >/dev/null 2>&1 && [[ "$ZSH_THEME" != "powerlevel10k/powerlevel10k" ]]; then
    eval "$(starship init zsh)"
fi

# ==============================================================================
# 5. ENVIRONMENT & PATH
# ==============================================================================

# Default Editor: Neovim
export EDITOR="nvim"
export VISUAL="nvim"

# Alacritty: export TERM so inner tools (nvim, tmux) know the outer terminal
export TERM="${TERM:-xterm-256color}"

# Homebrew — macOS (Apple Silicon / Intel) and Linux (Linuxbrew)
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
elif [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# User-local bin
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]]        && export PATH="$HOME/bin:$PATH"

# Claude Code Agent Teams (Experimental Multi-Agent Orchestrator)
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1


# ==============================================================================
# 6. TMUX UTILITIES
# ==============================================================================

# Prevent Zsh themes from hijacking tmux pane/window titles
case "$TERM" in
    screen*|tmux*)
        DISABLE_AUTO_TITLE="true"
        ;;
esac

# Programmatic pane title setter — call as: rename-pane "my title"
rename-pane() {
    printf "\033]2;%s\033\\" "$1"
}

# Ghostty: propagate kitty-graphics capability into tmux panes so plugins like
# mermaid.nvim detect it (tmux masks TERM_PROGRAM as "tmux" inside panes).
# The export covers a server freshly started by the auto-attach below (the
# server inherits this shell's env); set-environment covers attaching to an
# already-running server.
if [[ $TERM_PROGRAM == ghostty ]]; then
    export KITTY_WINDOW_ID="${KITTY_WINDOW_ID:-1}"
    tmux set-environment -g KITTY_WINDOW_ID 1 2>/dev/null
fi

# Auto-attach or create a persistent 'main' tmux session when launching
# Alacritty directly (mirrors Ghostty's command = tmux new-session -A -s main).
if [[ -z "$TMUX" ]] && command -v tmux >/dev/null; then
    exec tmux new-session -A -s main
fi

# ==============================================================================
# 7. CLIPBOARD COMPATIBILITY (Linux xclip / macOS pbcopy shim)
# ==============================================================================

# Provide pbcopy / pbpaste on Linux so macOS-era scripts still work
if [[ "$OSTYPE" != darwin* ]]; then
    if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
        alias pbcopy='wl-copy'
        alias pbpaste='wl-paste'
    elif command -v xclip >/dev/null 2>&1; then
        alias pbcopy='xclip -selection clipboard'
        alias pbpaste='xclip -selection clipboard -o'
    elif command -v xsel >/dev/null 2>&1; then
        alias pbcopy='xsel --clipboard --input'
        alias pbpaste='xsel --clipboard --output'
    elif [[ -n "${IS_WSL:-}" ]] && command -v clip.exe >/dev/null 2>&1; then
        alias pbcopy='clip.exe'
        alias pbpaste='powershell.exe -NoProfile -Command "Get-Clipboard"'
    fi
fi

# ==============================================================================
# LIGHTNING-FAST COPYLAST (0ms re-execution, captures actual terminal output)
# ==============================================================================
autoload -Uz add-zsh-hook

_copylast_preexec() {
    # Don't overwrite the last command if running copylast itself
    if [[ "$1" =~ ^[[:space:]]*copylast([[:space:]]|$) ]]; then
        _copylast_is_self=1
        return
    fi
    _copylast_is_self=0
    _copylast_cmd="$1"
    if [[ -n "$TMUX" ]]; then
        local _out
        _out=$(tmux display-message -p "#{history_size} #{cursor_y}" 2>/dev/null) || true
        if [[ -n "$_out" ]]; then
            local hist="${_out%% *}"
            local cy="${_out##* }"
            _copylast_start_abs=$(( hist + cy ))
        fi
    fi
}

_copylast_precmd() {
    if [[ "${_copylast_is_self:-0}" -eq 1 ]]; then
        _copylast_is_self=0
        return
    fi
    if [[ -n "$TMUX" && -n "$_copylast_start_abs" ]]; then
        local _out
        _out=$(tmux display-message -p "#{history_size} #{cursor_y}" 2>/dev/null) || true
        if [[ -n "$_out" ]]; then
            local end_hist="${_out%% *}"
            local end_cy="${_out##* }"
            _copylast_saved_start="$_copylast_start_abs"
            _copylast_saved_end=$(( end_hist + end_cy - 1 ))
            _copylast_saved_cmd="${_copylast_cmd}"
            tmux set-option -p @copylast_start "$_copylast_saved_start" \; \
                 set-option -p @copylast_end "$_copylast_saved_end" \; \
                 set-option -p @copylast_cmd "$_copylast_saved_cmd" 2>/dev/null || true
        fi
        unset _copylast_start_abs
    fi
}

add-zsh-hook preexec _copylast_preexec
add-zsh-hook precmd _copylast_precmd

# Copy last command output (stdout + stderr) with zero latency via native binary
copylast() {
    if [[ -x "$HOME/bin/copylast" ]]; then
        "$HOME/bin/copylast" "$@"
    elif (( $+commands[copylast] )); then
        command copylast "$@"
    else
        echo "copylast: binary not found at $HOME/bin/copylast" >&2
        return 1
    fi
}


# Cross-platform 'open' command: macOS has it natively, Linux uses xdg-open, WSL uses cmd.exe
if [[ "$OSTYPE" != darwin* ]] && ! command -v open >/dev/null; then
    open() {
        if command -v xdg-open >/dev/null; then
            xdg-open "$@" &>/dev/null &
        elif [[ -n "${IS_WSL:-}" ]] && command -v cmd.exe >/dev/null; then
            cmd.exe /c start "" "$@" &>/dev/null &
        else
            echo "open: no handler found for $1" >&2
            return 1
        fi
    }
fi

# ==============================================================================
# 9. SCREENSHOT UTILITY (Linux + macOS)
# ==============================================================================
unalias snap 2>/dev/null
snap() {
    local dir="$HOME/Pictures/Screenshots"
    mkdir -p "$dir"
    local filepath="$dir/Screenshot_$(date +%Y%m%d_%H%M%S).png"

    if [[ "$OSTYPE" == darwin* ]]; then
        screencapture "$filepath"
        if [[ -f "$filepath" ]]; then
            osascript -e "set the clipboard to (read (POSIX file \"$filepath\") as «class PNGf»)"
            echo "Captured: $filepath (copied to clipboard)"
        fi
    elif command -v gnome-screenshot >/dev/null; then
        gnome-screenshot -f "$filepath" && xclip -selection clipboard -t image/png < "$filepath"
        echo "Captured: $filepath (copied to clipboard)"
    elif command -v scrot >/dev/null; then
        scrot "$filepath" && xclip -selection clipboard -t image/png < "$filepath"
        echo "Captured: $filepath (copied to clipboard)"
    else
        echo "No screenshot tool found. Install gnome-screenshot or scrot."
    fi
}

# ==============================================================================
# 10. ALIASES
# ==============================================================================

# Fleet Multi-Agent Worktree Orchestrator
alias fsp='fleet spawn'
alias fbc='fleet broadcast'
alias fkp='fleet keep'
alias fdf='fleet diff'
alias fkl='fleet kill'
alias fls='fleet ls'
alias fdoc='fleet doctor'
alias fat='fleet attach'
alias flog='fleet logs'
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/fleet/fleet.zsh" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/fleet/fleet.zsh"


# Quick access & Application Openers
alias lg="lazygit"
alias mu="mupdf"
unalias om 2>/dev/null
unalias mt 2>/dev/null
if [[ "$OSTYPE" == darwin* ]]; then
    function om {
        local target="${1:-}"
        [[ -n "$target" ]] || { echo "Usage: om <file.md>"; return 1; }
        open -a "One Markdown" "$target"
    }
    function mt {
        local target="${1:-}"
        [[ -n "$target" ]] || { echo "Usage: mt <file.md>"; return 1; }
        open -na "Mark Text" --args "$(cd "$(dirname "$target")" && pwd)/$(basename "$target")"
    }
    alias prev='open -a Preview'
    alias preview='open -a Preview'
    alias finder='open'
    alias of='open -R'
else
    function om {
        local target="${1:-}"
        [[ -n "$target" ]] || { echo "Usage: om <file.md>"; return 1; }
        if command -v glow >/dev/null; then
            glow -p "$target"
        elif command -v xdg-open >/dev/null; then
            xdg-open "$target" &>/dev/null &
        else
            echo "No Markdown viewer found. Install glow or xdg-utils."
            return 1
        fi
    }
    function mt {
        local target="${1:-}"
        [[ -n "$target" ]] || { echo "Usage: mt <file.md>"; return 1; }
        if command -v marktext >/dev/null; then
            marktext "$target" &
        elif command -v flatpak >/dev/null; then
            flatpak run com.github.marktext.marktext "$target" &
        else
            echo "Mark Text not found. Install marktext or flatpak Mark Text."
            return 1
        fi
    }
    alias prev='xdg-open'
    alias preview='xdg-open'
    alias finder='xdg-open'
    alias of='xdg-open'
fi
alias omd='om'
alias onemarkdown='om'
alias marktext='mt'

# Yazi shell wrapper (changes terminal PWD on exit)
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Open lazygit for terminal-configs dotfiles repo
alias lgd="lazygit --path \"$DOTFILES\""

# Yazi image preview protocol for Ghostty
export YAZI_IMAGE_PROTOCOL="ghostty"

# Git shortcuts
alias gis='git rev-parse --is-inside-work-tree'
alias gc='git clone'
alias gs='git status -sb'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gl='git log --oneline --graph --decorate -n 20'
alias gaa='git add -A'
alias gnc='gh-ns-clone'
alias gnf='gh-ns-fork'
alias gnn='gh-ns-new'
alias gnp='gh-ns-promote'
alias gns='gh-ns-status'

# Directory Navigation & Quick Jumps
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -p'

# iCloud Drive & Markdown notes (synced via iCloud)
: "${ICLOUD_DRIVE:=$HOME/Library/Mobile Documents/com~apple~CloudDocs}"
: "${ICLOUD_MD:=$ICLOUD_DRIVE/Markdown}"
alias icloud='cd "$ICLOUD_DRIVE"'
alias mdf='cd "$ICLOUD_MD"'

# Github workspace (~/Github) — your repos live in ~/Github/<owner>/
: "${DOTFILES:=$HOME/dotfiles}"
: "${GITHUB_ROOT:=$HOME/Github}"

# Your GitHub owner dir, resolved lazily from gh auth (override with GH_USER)
gh_user_dir() {
  local owner="${GH_USER:-}"
  [[ -z "$owner" ]] && owner=$(gh api user -q .login 2>/dev/null)
  [[ -n "$owner" ]] && echo "$GITHUB_ROOT/$owner"
}
alias ghn='cd "$(gh_user_dir)"'
alias ghex='cd "$GITHUB_ROOT/explore"'
alias ghws='cd "$GITHUB_ROOT/workspace"'
alias ghroot='cd "$GITHUB_ROOT"'

# cd into any repo in your namespace: ghr [repo-name]
ghr() {
  local dir
  dir=$(gh_user_dir) || { echo "gh: not authenticated and GH_USER not set" >&2; return 1 }
  if [[ $# -eq 0 ]]; then
    ls -1 "$dir" 2>/dev/null
    return 0
  fi
  cd "$dir/$1" || {
    echo "Unknown repo: $1 (try: ghr with no args to list)"
    return 1
  }
}

# Data Engineering & Quick Inspection
alias headcsv='head -n 20'
alias tailcsv='tail -n 20'
alias prettyjson='python3 -m json.tool'
alias duck='duckdb'

# Docker & Container Shortcuts
alias d='docker'
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dlogs='docker logs -f --tail=100'

# tmux shortcuts
alias ta='tmux attach -t main || tmux new-session -s main'
alias tl='tmux list-sessions'
alias tk='tmux kill-session -t'

# Launch a brand new Ghostty window attached to a fresh tmux session
ghostty-new() {
    local sess="${1:-$(date +%Y-%m-%d_%H-%M)}"
    local ghostty_bin="/Applications/Ghostty.app/Contents/MacOS/ghostty"
    if [[ ! -x "$ghostty_bin" ]]; then
        ghostty_bin=$(command -v ghostty 2>/dev/null || echo "ghostty")
    fi
    "$ghostty_bin" -e tmux new-session -s "$sess" >/dev/null 2>&1 &
}

# Developer & Data Project Scaffolding Utilities
mkpy() {
    local proj="${1:-my_python_project}"
    mkdir -p "$proj"/{src/"$proj",tests,data/{raw,processed},notebooks,scripts}
    touch "$proj"/{README.md,.env,.gitignore,requirements.txt,src/"$proj"/__init__.py,src/"$proj"/main.py,tests/__init__.py}
    echo -e "python-version = \"3.11\"\n__pycache__/\n*.pyc\n.env\n.venv/\ndata/\n.pytest_cache/\n.ipynb_checkpoints/" > "$proj/.gitignore"
    echo -e "# $proj\n\nGenerated Python/Data engineering project repository." > "$proj/README.md"
    echo "print('Project $proj initialized successfully!')" > "$proj/src/$proj/main.py"
    (cd "$proj" && git init >/dev/null 2>&1 && echo "✓ Initialized git repo in $proj")
    echo "✓ Created Python project scaffold: $proj/"
}

mkts() {
    local proj="${1:-my_ts_project}"
    mkdir -p "$proj"/{src,tests,dist}
    touch "$proj"/{README.md,.env,.gitignore,src/index.ts}
    echo -e "node_modules/\ndist/\n.env\n*.log" > "$proj/.gitignore"
    echo -e "# $proj\n\nGenerated TypeScript project repository." > "$proj/README.md"
    echo "console.log('Project $proj initialized successfully!');" > "$proj/src/index.ts"
    (cd "$proj" && git init >/dev/null 2>&1 && echo "✓ Initialized git repo in $proj")
    echo "✓ Created TypeScript project scaffold: $proj/"
}

# Enable vi command line editing mode
bindkey -v

# Map standard vim movements inside history search
bindkey '^K' up-line-or-history
bindkey '^J' down-line-or-history

# ==============================================================================
# GIT WORKTREE + CLAUDE SESSION WORKFLOW
# ==============================================================================
# wt-new <branch> [base]  — create worktree sibling dir, cd into it, launch claude
wt-new() {
  local branch=$1 base=${2:-HEAD}
  [[ -z "$branch" ]] && { echo "Usage: wt-new <branch> [base]"; return 1 }
  local root; root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not in a git repo"; return 1 }
  local dir="${root%/*}/${branch}"
  git worktree add -b "$branch" "$dir" "$base" || return 1
  cd "$(realpath "$dir")" && claude --name "$branch"
}

# wt-tmux-attach — fzf-pick an existing worktree, open in a new tmux window with claude
wt-tmux-attach() {
  local row; row=$(git worktree list 2>/dev/null | tail -n +2 \
    | fzf --height=50% --reverse --prompt="worktree> ") || return 0
  local dir; dir=$(awk '{print $1}' <<< "$row")
  local name; name=$(basename "$dir")
  tmux new-window -c "$dir" -n "$name" "zsh -ic 'claude --name $name; exec zsh'"
}

# wt-rm [branch] — remove a worktree (fzf picker if no arg)
wt-rm() {
  local branch=${1:-$(git worktree list 2>/dev/null | tail -n +2 \
    | fzf --height=50% --reverse --prompt="remove> " | awk '{print $NF}' | tr -d '[]')}
  [[ -z "$branch" ]] && return 0
  local dir; dir=$(git worktree list | awk -v b="[$branch]" '$NF==b {print $1}')
  git worktree remove --force "$dir" && git branch -d "$branch"
}

# ==============================================================================
# WORKMUX & SESH WORKFLOW INTEGRATIONS
# ==============================================================================

# SESH Smart Session Manager helpers
sesh-sessions() {
  sesh connect "$(sesh list -t -c -z | fzf-tmux -p 75%,60% \
    --no-sort --border-label ' sesh sessions ' --prompt '⚡  ' \
    --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
    --bind 'tab:down,btab:up' \
    --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
    --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' \
    --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c)' \
    --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' \
    --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~/Github)' \
    --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)' \
    --preview-window 'right:55%' \
    --preview 'sesh preview {}')"
}
zle -N sesh-sessions
bindkey -M emacs '\es' sesh-sessions
bindkey -M viins '\es' sesh-sessions
bindkey -M vicmd '\es' sesh-sessions

# Workmux: Zero-friction git worktrees + tmux windows
alias wm='workmux'
alias wma='workmux add'
alias wml='workmux list'
alias wmls='workmux list'
alias wmo='workmux open'
alias wmc='workmux close'
alias wmm='workmux merge'
alias wmr='workmux remove'
alias wmrm='workmux remove'
alias wmd='workmux dashboard'
alias wms='workmux sidebar'

# wmux: Smart wrapper that forwards subcommands or creates worktrees directly
wmux() {
  if [ $# -eq 0 ]; then
    workmux
  elif [[ "$1" =~ ^(add|open|close|list|ls|remove|rm|merge|rebase|dashboard|sidebar|setup|config|resurrect|init|sync-files|run|capture|send|wait) ]]; then
    workmux "$@"
  else
    workmux add "$@"
  fi
}


# ==============================================================================
# CLAUDE CODE 10X DEVELOPER EXTENSIONS
# ==============================================================================

# cco: Standard Claude Code wrapper to pass arguments
cco() {
  claude "$@"
}

# cinit: Generate a starter CLAUDE.md file
cinit() {
  if [[ -f CLAUDE.md ]]; then
    echo "CLAUDE.md already exists."
    return 0
  fi
  cat << 'EOF' > CLAUDE.md
# CLAUDE.md

## Build and Test Commands
- Build: `npm run build` or equivalent
- Test: `npm test` or equivalent

## Style Guidelines
- Maintain consistent code style and formatting.
- Keep lines concise and documented.
EOF
  echo "✓ Created starter CLAUDE.md"
}

# cbug: Send the current clipboard contents (e.g. error/stacktrace) to Claude to debug
cbug() {
  local clipboard=""
  if [[ "$OSTYPE" == darwin* ]]; then
    clipboard=$(pbpaste)
  elif command -v xclip >/dev/null; then
    clipboard=$(xclip -selection clipboard -o)
  elif command -v xsel >/dev/null; then
    clipboard=$(xsel --clipboard --output)
  fi

  if [[ -z "$clipboard" ]]; then
    echo "Clipboard is empty."
    return 1
  fi

  echo "Sending clipboard to Claude for debugging..."
  claude -p "I am encountering this error/issue. Please diagnose and provide a solution:
$clipboard"
}

# creview: Ask Claude to review unstaged or staged git changes
creview() {
  local diff
  diff=$(git diff)
  if [[ -z "$diff" ]]; then
    diff=$(git diff --cached)
  fi
  if [[ -z "$diff" ]]; then
    echo "No unstaged or staged changes to review."
    return 0
  fi
  echo "Reviewing changes with Claude..."
  claude -p "Please review these git changes. Identify potential bugs, edge cases, style issues, or optimizations:
$diff"
}

# cplan: Ask Claude to create a detailed implementation plan for a task
cplan() {
  if [[ -z "$*" ]]; then
    echo "Usage: cplan <task description>"
    return 1
  fi
  claude -p "Please create a detailed step-by-step implementation plan for the following task: $*"
}

# cdoc: Ask Claude to document a file
cdoc() {
  if [[ -z "$1" ]]; then
    echo "Usage: cdoc <filename>"
    return 1
  fi
  if [[ ! -f "$1" ]]; then
    echo "File not found: $1"
    return 1
  fi
  echo "Generating documentation for $1..."
  claude -p "Please write high-quality documentation, comments, and docstrings for this file:
$(cat "$1")"
}

# ctest: Ask Claude to write tests for a file
ctest() {
  if [[ -z "$1" ]]; then
    echo "Usage: ctest <filename>"
    return 1
  fi
  if [[ ! -f "$1" ]]; then
    echo "File not found: $1"
    return 1
  fi
  echo "Generating unit tests for $1..."
  claude -p "Please write comprehensive unit tests for this file:
$(cat "$1")"
}

# cgc: Generate a conventional commit message from git diff and commit
cgc() {
  local diff
  diff=$(git diff --cached)
  if [[ -z "$diff" ]]; then
    diff=$(git diff)
  fi
  if [[ -z "$diff" ]]; then
    echo "No changes to commit."
    return 0
  fi
  echo "Analyzing diff and generating commit message..."
  local msg
  msg=$(claude -p "Generate a short, concise conventional commit message for the following diff. Output ONLY the commit message itself, nothing else:
$diff")
  
  if [[ -n "$msg" ]]; then
    echo -e "\nProposed commit message:\n$msg\n"
    echo -n "Commit with this message? [y/N] "
    read -r -k 1 reply
    echo ""
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      git commit -m "$msg"
    fi
  else
    echo "Failed to generate commit message."
  fi
}

# ==============================================================================
# MODERN DEV TOOLS & FUZZY WORKFLOWS
# ==============================================================================

# Zoxide (Smart cd) Hook
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

# Direnv Hook
if command -v direnv >/dev/null; then
  eval "$(direnv hook zsh)"
fi

# FZF Shell Integration & Patched Command Defaults
if command -v fzf >/dev/null 2>&1; then
  # Source fzf completion & key bindings (Homebrew & standard paths supported)
  if [[ -d "/opt/homebrew/opt/fzf/shell" ]]; then
    source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2>/dev/null
    source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh" 2>/dev/null
  elif [[ -d "/usr/local/opt/fzf/shell" ]]; then
    source "/usr/local/opt/fzf/shell/completion.zsh" 2>/dev/null
    source "/usr/local/opt/fzf/shell/key-bindings.zsh" 2>/dev/null
  else
    source <(fzf --zsh) 2>/dev/null
  fi

  # Explicitly bind fzf widgets for vi mode & default keymaps
  if zle -l fzf-history-widget 2>/dev/null; then
    bindkey '^R' fzf-history-widget
    bindkey -M viins '^R' fzf-history-widget
    bindkey -M vicmd '^R' fzf-history-widget
  fi
  if zle -l fzf-file-widget 2>/dev/null; then
    bindkey '^T' fzf-file-widget
    bindkey -M viins '^T' fzf-file-widget
    bindkey -M vicmd '^T' fzf-file-widget
  fi
  if zle -l fzf-cd-widget 2>/dev/null; then
    bindkey '\ec' fzf-cd-widget
    bindkey -M viins '\ec' fzf-cd-widget
    bindkey -M vicmd '\ec' fzf-cd-widget
  fi

  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'

    # Use fd inside the ** completion popup
    _fzf_compgen_path() {
      fd --hidden --follow --exclude ".git" . "$1"
    }

    _fzf_compgen_dir() {
      fd --type d --hidden --follow --exclude ".git" . "$1"
    }
  fi
fi

# Modern CLI Replacements Aliases
alias venv='uv venv && source .venv/bin/activate'

if command -v eza >/dev/null; then
  alias l='eza -la --icons --group-directories-first'
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --group-directories-first'
  alias la='eza -la --icons --group-directories-first'
  alias lsd='eza -la --icons --sort=mod --reverse'
  alias tree='eza --tree --icons'
else
  alias l='ls -lah'
  alias lsd='ls -laht'
fi

# Taskwarrior Ergonomic Aliases
if command -v task >/dev/null; then
  alias t='task'
  alias ta='task add'
  alias tl='task list'
  alias tn='task next'
  alias tui='taskwarrior-tui'
  alias tdev='task project:dev list'
fi

if command -v bat >/dev/null; then
  alias cat='bat --style=header,grid,snip --theme=ansi'
fi

if command -v duf >/dev/null; then
  alias df='duf'
fi

if command -v dust >/dev/null; then
  alias du='dust'
fi


# gb: Interactive Git Branch Switcher with Log Preview
unalias gb 2>/dev/null
gb() {
  local branch
  branch=$(git branch --color=always | fzf --ansi --no-multi --preview-window right:65% --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%h %ad %s" {1}') &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# gshow: Interactive Git Commit History Diff Browser
gshow() {
  git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --preview 'f(v)={ set -- $(echo "$v" | grep -o "[a-f0-9]\{7,\}"); [ $# -eq 0 ] || git show --color=always "$1"; }; f {}' \
      --header "Enter to view commit details" \
      --bind "enter:execute(git show --color=always {1} | less -R)"
}

# ==============================================================================
# 12. 10X DEVELOPER WORKFLOW UTILITIES
# ==============================================================================

# --- Git Power Moves ---
alias groot='cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"'
alias gundo='git reset --soft HEAD~1'
alias gwip='git add -A && git commit -m "wip: save point [skip ci]" --no-verify'
alias gunwip='git log -n 1 --pretty=%B 2>/dev/null | grep -q "wip: save point" && git reset HEAD~1'
alias gpristine='git reset --hard && git clean -dfx'
alias gignored='git status --ignored -s | grep "^!!"'
alias gauthors='git shortlog -sn --no-merges'

# --- Fast Clipboard Ergonomics ---
alias cbranch='git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d "\n" | pbcopy && echo "✓ Copied branch: $(pbpaste)"'
alias csha='git rev-parse --short HEAD 2>/dev/null | tr -d "\n" | pbcopy && echo "✓ Copied SHA: $(pbpaste)"'

cpath() {
  local p="${1:-$PWD}"
  local abs_path
  abs_path=$(realpath "$p" 2>/dev/null || echo "$p")
  printf "%s" "$abs_path" | pbcopy
  echo "✓ Copied path: $abs_path"
}

cpfile() {
  if [[ -f "$1" ]]; then
    cat "$1" | pbcopy
    local lines
    lines=$(wc -l < "$1" | tr -d ' ')
    echo "✓ Copied contents of $1 ($lines lines) to clipboard"
  else
    echo "Error: File not found: $1"
    return 1
  fi
}

# --- Ports, Networking & Local Development ---
port() {
  if [[ -z "$1" ]]; then
    echo "Usage: port <port_number>"
    return 1
  fi
  lsof -iTCP:"$1" -sTCP:LISTEN -n -P
}

killport() {
  if [[ -z "$1" ]]; then
    echo "Usage: killport <port_number>"
    return 1
  fi
  local pid
  pid=$(lsof -tiTCP:"$1" -sTCP:LISTEN)
  if [[ -n "$pid" ]]; then
    echo "$pid" | xargs kill -9
    echo "✓ Killed process(es) $pid on port $1"
  else
    echo "No listening process found on port $1"
  fi
}

serve() {
  local p="${1:-8000}"
  echo "Serving $PWD at http://localhost:$p"
  python3 -m http.server "$p"
}

alias myip='curl -s https://ipinfo.io/json'

cheat() {
  if [[ -z "$1" ]]; then
    echo "Usage: cheat <topic>"
    return 1
  fi
  curl -s "https://cheat.sh/$1"
}

# --- Interactive FZF Superpowers ---
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m --header='[Kill Process: TAB to multi-select, ENTER to kill]' --preview 'echo {}' | awk '{print $2}')
  if [[ -n "$pid" ]]; then
    echo "$pid" | xargs kill -${1:-9}
    echo "✓ Killed PID(s): $pid"
  fi
}

fo() {
  local file
  file=$(fzf --preview 'bat --style=numbers --color=always --line-range :500 {} 2>/dev/null || cat {}')
  [[ -n "$file" ]] && ${EDITOR:-nvim} "$file"
}

fenv() {
  env | sort | fzf --header='[Environment Variables]'
}

fdocker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker command not found" >&2
    return 1
  fi
  local cid
  cid=$(docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null | \
    fzf --header-lines=1 --reverse --header="[Select Docker Container to Exec]" | awk '{print $1}')
  if [[ -n "$cid" ]]; then
    echo "Attaching to container $cid..."
    docker exec -it "$cid" /bin/sh -c "[ -e /bin/bash ] && exec /bin/bash || exec /bin/sh"
  fi
}

fssh() {
  local host
  host=$(awk '/^Host / && !/\*/ {print $2}' ~/.ssh/config 2>/dev/null | fzf --reverse --header="[Select SSH Host]")
  if [[ -n "$host" ]]; then
    if [[ -n "$TMUX" ]]; then
      tmux new-window -n "ssh:$host" "ssh $host"
    else
      ssh "$host"
    fi
  fi
}

handoff() {
  "$HOME/bin/session-handoff" "$@"
}
alias aghandoff='handoff'
alias ag-handoff='handoff'

matrix() {
  "$HOME/bin/tmux-agent-matrix" "${1:-2}" "${2:-claude}"
}

gb-clean() {
  local default_branch
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  default_branch="${default_branch:-main}"
  echo "Pruning branches merged into $default_branch..."
  git checkout "$default_branch" 2>/dev/null && git pull --ff-only 2>/dev/null
  git branch --merged "$default_branch" | grep -v "^\*\|master\|main\|dev" | xargs -n 1 git branch -d 2>/dev/null || true
  echo "✓ Local merged branches cleaned."
}

# --- Smart Shell Ergonomics ---
mcd() {
  mkdir -p "$1" && cd "$1"
}

alias path='echo -e ${PATH//:/\\n}'

extract() {
  if [[ -z "$1" ]]; then
    echo "Usage: extract <archive_file>"
    return 1
  fi
  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"     ;;
      *.tar.gz)    tar xzf "$1"     ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar x "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xf "$1"      ;;
      *.tbz2)      tar xjf "$1"     ;;
      *.tgz)       tar xzf "$1"     ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *.tar.xz)    tar xf "$1"      ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "Error: '$1' is not a valid file"
    return 1
  fi
}

# ==============================================================================
# KEYBINDINGS
# ==============================================================================
# Map standard emacs/vi shortcuts
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# Map Alt+K to clear line after cursor (kill-line)
bindkey '\ek' kill-line
bindkey '^[k' kill-line
bindkey -M viins '\ek' kill-line
bindkey -M vicmd '\ek' kill-line

# Remove Ctrl+K from kill-line (used for history navigation in vi mode)
bindkey -r '^K'
bindkey '^K' up-line-or-history
bindkey -M viins '^K' up-line-or-history
bindkey -M vicmd '^K' up-line-or-history

[[ -d "$HOME/.claude/bin" ]] && export PATH="$HOME/.claude/bin:$PATH"

unalias wmo 2>/dev/null || true
wmo() {
  if [ -n "$1" ]; then
    workmux open "$1"
  else
    local b
    b=$(workmux list 2>/dev/null | tail -n +2 | grep -v '(here)' | awk '{print $1}' | fzf --prompt='Select worktree: ' --reverse)
    [ -n "$b" ] && workmux open "$b"
  fi
}
