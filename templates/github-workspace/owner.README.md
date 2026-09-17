# ~/Github/<owner>

Your GitHub mirror: every repo you own lives here, one folder per remote
`<owner>/<repo>` — clone, branch, and push from here.

Suggested flow for brand-new work:

1. `gh-ns-new <name>` — scaffold a local-only project in `~/Github/_local/projects/`
2. build until it deserves a remote
3. `gh-ns-promote` — create `github.com/<owner>/<name>` and move it here
