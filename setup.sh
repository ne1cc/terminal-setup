#!/usr/bin/env bash
# setup.sh - Portable, idempotent terminal-config installer.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.terminal-configs-backups/$(date +%Y%m%d-%H%M%S)"
INSTALL_PACKAGES=false
SKIP_PLUGINS=false
WITH_WORKSPACE=false
DRY_RUN=false

usage() {
  cat <<'EOF'
Usage: ./setup.sh [--install-packages] [--skip-plugins] [--with-workspace] [--dry-run]

Links the portable terminal configuration into $HOME. Existing files are moved
to ~/.terminal-configs-backups/<timestamp> before they are replaced.

Options:
  --install-packages  Run brew bundle with the platform's Brewfile.
  --skip-plugins      Do not install TPM or sync Neovim plugins.
  --with-workspace    Scaffold a ~/Github/<your-username> workspace (needs gh or prompts).
  --dry-run           Print planned changes without modifying the machine.
EOF
}

run() {
  if "$DRY_RUN"; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

backup_path() {
  local path="$1"
  local relative="${path#"$HOME"/}"
  run mkdir -p "$BACKUP_DIR/$(dirname "$relative")"
  run mv "$path" "$BACKUP_DIR/$relative"
}

link_path() {
  local source="$1"
  local destination="$2"

  if [[ -L "$destination" && "$(readlink "$destination")" == "$source" ]]; then
    printf '  unchanged: %s\n' "$destination"
    return
  fi

  if [[ -e "$destination" || -L "$destination" ]]; then
    printf '  backing up: %s\n' "$destination"
    backup_path "$destination"
  fi

  run mkdir -p "$(dirname "$destination")"
  run ln -s "$source" "$destination"
  printf '  linked: %s\n' "$destination"
}

for argument in "$@"; do
  case "$argument" in
    --install-packages) INSTALL_PACKAGES=true ;;
    --skip-plugins) SKIP_PLUGINS=true ;;
    --with-workspace) WITH_WORKSPACE=true ;;
    --dry-run) DRY_RUN=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$argument" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$(uname -s)" == "Darwin" ]]; then
  PLATFORM=macOS
  BREWFILE="$REPO_DIR/Brewfile"
elif grep -qi microsoft /proc/version 2>/dev/null; then
  PLATFORM=WSL
  BREWFILE="$REPO_DIR/Brewfile.linux"
else
  PLATFORM=Linux
  BREWFILE="$REPO_DIR/Brewfile.linux"
fi

printf '==> Installing terminal configs for %s\n' "$PLATFORM"
run mkdir -p "$CONFIG_DIR" "$HOME/bin"

# Generate Taskwarrior config dynamically if template exists
if [[ -f "$REPO_DIR/.taskrc.template" ]]; then
  THEME_PATH=""
  if [ -f "/opt/homebrew/share/doc/task/rc/dark-256.theme" ]; then
    THEME_PATH="/opt/homebrew/share/doc/task/rc/dark-256.theme"
  elif [ -f "/usr/local/share/doc/task/rc/dark-256.theme" ]; then
    THEME_PATH="/usr/local/share/doc/task/rc/dark-256.theme"
  elif [ -f "/usr/share/doc/task/rc/dark-256.theme" ]; then
    THEME_PATH="/usr/share/doc/task/rc/dark-256.theme"
  fi

  if [ -n "$THEME_PATH" ]; then
    sed "s|__THEME_PATH__|$THEME_PATH|g" "$REPO_DIR/.taskrc.template" > "$REPO_DIR/.taskrc"
  else
    sed "/__THEME_PATH__/d" "$REPO_DIR/.taskrc.template" > "$REPO_DIR/.taskrc"
  fi
fi

for dotfile in .zshrc .zprofile .p10k.zsh .tmux.conf .gitconfig .taskrc .inputrc .bashrc .bash_profile; do
  [[ -f "$REPO_DIR/$dotfile" ]] && link_path "$REPO_DIR/$dotfile" "$HOME/$dotfile"
done

for config in nvim ghostty alacritty lazygit yazi starship.toml glow fleet sesh workmux; do
  link_path "$REPO_DIR/.config/$config" "$CONFIG_DIR/$config"
done

if [[ "$PLATFORM" == "macOS" && -d "$REPO_DIR/.config/karabiner" ]]; then
  link_path "$REPO_DIR/.config/karabiner" "$CONFIG_DIR/karabiner"
fi

for script in "$REPO_DIR"/bin/*; do
  [[ -f "$script" ]] || continue
  link_path "$script" "$HOME/bin/$(basename "$script")"
done

if "$WITH_WORKSPACE"; then
  if "$DRY_RUN"; then
    printf '[dry-run] %s/bin/setup-github-workspace\n' "$REPO_DIR"
  elif [[ -f "$REPO_DIR/bin/setup-github-workspace" ]]; then
    bash "$REPO_DIR/bin/setup-github-workspace"
  else
    printf 'setup-github-workspace not found in %s/bin\n' "$REPO_DIR" >&2
  fi
fi

# Ghostty now uses ~/.config/ghostty/config on every supported platform. Remove
# the obsolete macOS location only when it is our previously-managed symlink;
# loading both files applies keybindings twice and produces duplicate errors.
LEGACY_GHOSTTY_CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
if [[ -L "$LEGACY_GHOSTTY_CONFIG" && "$(readlink "$LEGACY_GHOSTTY_CONFIG")" == "$REPO_DIR/.config/ghostty/config" ]]; then
  printf '  removing obsolete Ghostty config: %s\n' "$LEGACY_GHOSTTY_CONFIG"
  run rm "$LEGACY_GHOSTTY_CONFIG"
fi

if "$INSTALL_PACKAGES"; then
  if ! command -v brew >/dev/null 2>&1; then
    printf 'Homebrew is required for --install-packages.\n' >&2
    exit 1
  fi
  run brew bundle --file="$BREWFILE"
fi

if ! "$SKIP_PLUGINS"; then
  if command -v git >/dev/null 2>&1 && [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    run mkdir -p "$HOME/.tmux/plugins"
    run git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  fi

  if command -v nvim >/dev/null 2>&1; then
    run nvim --headless '+Lazy! sync' +qa
  fi
fi

printf '\nDone. Backups, if any: %s\n' "$BACKUP_DIR"

