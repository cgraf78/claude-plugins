# memory-sync

Syncs Claude Code project memory directories to a cloud drive, so memory is shared
across machines even when the home directory path differs (e.g. `/Users/chris` vs `/home/chris`).

Each `~/.claude/projects/*/memory/` directory is replaced with a symlink pointing to a
consistent subdirectory on your cloud drive, derived by stripping the machine-specific
home prefix from the encoded path:

```
~/.claude/projects/-Users-chris-git/memory  →  <cloud-root>/git
~/.claude/projects/-home-chris-git/memory   →  <cloud-root>/git   (Linux, same dir)
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
