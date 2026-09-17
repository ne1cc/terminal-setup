# ==============================================================================
# fleet.zsh — Zsh Shell Integration, Aliases & Helper Layer for Fleet
# ==============================================================================
# Provides instant CLI aliases, fuzzy session pickers, and shell completions.
# ==============================================================================

# Quick Fleet Aliases
alias fsp='fleet spawn'
alias fbc='fleet broadcast'
alias fkp='fleet keep'
alias fdf='fleet diff'
alias fkl='fleet kill'
alias fls='fleet ls'
alias fdoc='fleet doctor'
alias fat='fleet attach'
alias flog='fleet logs'

# Interactive Fuzzy Fleet Selector (requires fzf)
fsel() {
    local selected_run
    selected_run=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep '^fleet-' | sed 's/^fleet-//' | fzf --reverse --header="🤖 Select Active Fleet Swarm" --prompt="Fleet > ")
    if [ -n "$selected_run" ]; then
        fleet attach "$selected_run"
    fi
}

# Fuzzy Fleet Diff Inspector
fzf-diff() {
    local selected_run
    selected_run=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep '^fleet-' | sed 's/^fleet-//' | fzf --reverse --header="📊 Select Fleet Swarm to Diff" --prompt="Diff > ")
    if [ -n "$selected_run" ]; then
        fleet diff "$selected_run" --stat
    fi
}
