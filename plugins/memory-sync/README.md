# memory-sync

Syncs Claude Code project memory directories to a cloud drive, so memory is shared
across machines even when the home directory path differs (e.g. `/Users/chris` vs `/home/chris`).

Each `~/.claude/projects/*/memory/` directory is replaced with a symlink pointing to a
consistent subdirectory on your cloud drive. The script reads the real project path from
session transcripts to derive a stable cloud subdirectory:

```
~/git/my-project  →  <cloud-root>/git/my-project
~/fbsource        →  <cloud-root>/fbsource       (same on any machine)
```

A `Stop` hook runs after every response to catch newly created project directories.
The hook exits immediately when nothing needs doing — no overhead in the common case.

## Requirements

- `bash`
- `jq`
- A cloud drive (Google Drive, Dropbox, iCloud, etc.)

## Setup

After installing, run `/memory-sync-setup` in any Claude Code session. Repeat on each
machine, pointing to the same cloud root path.

## Projects outside `$HOME`

If your projects live outside `$HOME` (e.g. `/data/users/$USER/`), add the prefix to
the `known_prefixes` array in `sync-memory.sh`. The script only links projects whose
real path matches a known prefix.
