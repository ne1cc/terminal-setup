# terminal-setup

A complete, reproducible terminal environment: **zsh + Oh My Zsh + Powerlevel10k,
tmux with a tuned keymap, Neovim (AstroNvim-based), Ghostty/Alacritty, and a
set of curated CLI tools** — installed with one command on macOS, Linux, and
WSL.

Everything is idempotent: run `./install` as many times as you like. Existing
configs are backed up, never silently overwritten.

## Quick start

```bash
git clone https://github.com/ne1cc/terminal-setup ~/dotfiles
cd ~/dotfiles && ./install
```

That's it. The installer will:

1. Verify `git` / `zsh` (installing zsh via Homebrew if needed)
2. Install Homebrew if missing (macOS)
3. Install Oh My Zsh and Powerlevel10k
4. Install every package from the platform Brewfile (asked for confirmation)
5. Symlink all dotfiles into `$HOME` (old files backed up to
   `~/.terminal-configs-backups/<timestamp>`)
6. Install tmux plugin manager (TPM) + plugins, sync Neovim plugins
7. Optionally set zsh as your default shell

### Options

| Flag | Effect |
|------|--------|
| `--with-workspace` | Also scaffold a `~/Github/<your-username>` workspace for your own repos |
| `--skip-packages` | Skip the brew bundle step |
| `--skip-plugins` | Skip TPM / Neovim plugin sync |
| `--yes` / `-y` | Non-interactive: assume yes |
| `--dry-run` | Show what would be linked, change nothing |

Already have the repo and just want the config links? `./setup.sh` does steps
5–6 on its own.

## What's inside

| Area | Highlights |
|------|------------|
| Shell | `.zshrc` with ~150 aliases/functions, vi-mode, fzf/zoxide/direnv integration, modern CLI replacements (eza, bat, duf, dust, fd) |
| Prompt | Powerlevel10k (`.p10k.zsh` tuned config; Starship available as fallback) |
| Multiplexer | `.tmux.conf` with sessionizer, scratchpad, pane helpers, resurrect/continuum |
| Editor | Neovim via AstroNvim with LSP, Telescope, and workflow plugins |
| Terminals | Ghostty + Alacritty configs; auto-attach to a persistent `main` tmux session |
| Git | `.gitconfig` with delta side-by-side diffs, sensible aliases, gh credential helper |
| Tasks | Taskwarrior config (generated from `.taskrc.template` per-machine) |
| Tools | ~30 helper scripts in `bin/` (tmux-*, gh-ns-*, sesh, session-handoff, …) |

Run `ls ~/bin` after install, or browse [`bin/`](bin/) — every script has a
usage header.

## The GitHub workspace layout

`./install --with-workspace` scaffolds an organized `~/Github` tree for **your
own** GitHub account (owner auto-detected via `gh auth login`, or pass it when
prompted):

```
~/Github/
  <your-username>/   # your repos — clone/push here
  _local/projects/   # local WIP with no remote yet
  config/  explore/  archive/  workspace/  _tools/
```

It also wires per-owner git identity via `includeIf`, so `~/Github/<you>/.gitconfig`
holds your name/email for those repos.

The `gh-ns-*` helper scripts (alias `gnn`, `gnp`, `gns`, `gnc`, `gnf`) manage
the local-only → published repo flow. They always resolve **your** account from
`gh` — nothing in this repo is hard-wired to its author.

## Requirements

- macOS (Apple Silicon or Intel), Linux, or WSL2
- `git` (and `curl`) — everything else is installed for you
- A [Nerd Font](https://www.nerdfonts.com/) in your terminal for the prompt
  icons (the macOS Brewfile installs one: `font-agave-nerd-font`)

## Customizing

- **Packages:** edit `Brewfile` (macOS) / `Brewfile.linux` (Linux + WSL), then
  `./setup.sh --install-packages`
- **Shell:** everything lives in `.zshrc` — it's plain zsh, no generated glue
- **Dotfile location:** the installer recommends cloning to `~/dotfiles`;
  if you clone elsewhere, update `DOTFILES` in `.zprofile`

## Uninstall

Remove the symlinks (they all point back to the repo):

```bash
ls -l ~/.zshrc ~/.tmux.conf ~/.config/nvim   # confirm they're symlinks
rm ~/.zshrc ~/.zprofile ~/.p10k.zsh ~/.tmux.conf ~/.gitconfig ~/.taskrc
rm -rf ~/.config/{nvim,ghostty,alacritty,lazygit,yazi,fleet,sesh,workmux}
rm ~/bin/{copylast,fleet,sesh-picker,...}    # see ls ~/bin
```

Backups of anything replaced during install remain in
`~/.terminal-configs-backups/`.

## Origin

This is the public, de-personalized distribution of
[`ne1cc/terminal-configs`](https://github.com/ne1cc/terminal-configs) (private):
the author's daily-driver setup, made reproducible for anyone. Personal
aliases, repos, and agent configs are stripped; everything here resolves
against *your* machine and *your* GitHub account.

## License

[MIT](LICENSE)
