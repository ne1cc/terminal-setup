# ~/Github

Organized home for everything GitHub-related on this machine.

```
~/Github/
  <your-username>/   # repos you own — clone/push from here
  _local/projects/   # local WIP with no remote yet
  _local/archive/    # old / non-synced trees
  config/            # machine config projects (dotfiles, scripts, docs)
  explore/           # clones of other people's repos for reading
  archive/           # finished or parked projects (see MANIFEST if present)
  workspace/         # scratch sandboxes and datasets
  _tools/            # helper scripts and exclude lists
```

## Conventions

- **Repos you push to GitHub** live in `~/Github/<your-username>/<repo>` — one
  folder level mirrors one GitHub owner, so remotes and identities stay aligned.
- **Read-only reference clones** of third-party repos go in `explore/`.
- **Unpublished experiments** start in `_local/projects/`; promote them with
  `gh-ns-promote` when they deserve a remote.
- `archive/` is for parked work; `gharchive`-style scripts should leave a note
  in the project folder or the exclude list in `_tools/`.

Run `bin/setup-github-workspace` (from the terminal-setup repo) to (re)create
this layout on a new machine.
