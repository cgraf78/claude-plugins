# memory-sync Plugin Design

**Date:** 2026-03-20
**Status:** Approved

## Problem

Claude Code stores per-project memory in `~/.claude/projects/<encoded-path>/memory/`. The
encoded path embeds the machine's home directory (e.g. `-Users-chris-git`), making it
impossible to share memory across machines by simply syncing the whole projects directory.

## Solution

A plugin that symlinks each `memory/` subdirectory to a cloud drive folder, using a logical
path scheme that is consistent across machines regardless of the home directory prefix.

## Path Mapping

Claude Code encodes absolute paths by replacing `/` with `-`:

```
/Users/chris       →  -Users-chris       →  <cloud-root>/
/Users/chris/git   →  -Users-chris-git   →  <cloud-root>/git
/home/chris/git    →  -home-chris-git    →  <cloud-root>/git   (same cloud dir)
```

The script strips the machine-specific `$HOME` prefix from the encoded name, leaving a
relative path that is consistent across machines. Both machines point to the same cloud
subdirectory.

**Known limitation:** Directory names containing `-` are indistinguishable from path
separators in Claude Code's encoding. `~/my-project` and `~/my/project` both encode with
`-` as separator. This is documented but acceptable for typical project structures.

## Components

### `scripts/sync-memory.sh`

Runs as a Claude Code `Stop` hook after every response.

- **Fast path:** Checks if all `~/.claude/projects/*/memory` entries are symlinks using
  pure bash (`[ -L ... ]`). Exits immediately if so — essentially zero overhead.
- **Slow path:** Triggered only when a new project directory appears (uncommon). Decodes
  the directory name, maps it to a cloud subdirectory, migrates any existing content,
  and creates the symlink.
- Reads config from `~/.claude/settings.json` under `"memory-sync".cloudRoot`.
- Skips project dirs whose encoded prefix doesn't match `$HOME` (other machines' dirs).

### `skills/memory-sync-setup/SKILL.md`

Invoked as `/memory-sync-setup`. Walks the user through first-time configuration:

1. Prompts for the cloud root path
2. Writes `"memory-sync".cloudRoot` to `~/.claude/settings.json`
3. Installs the `Stop` hook in `~/.claude/settings.json`
4. Runs the sync script once to wire up existing project dirs

### Config

Stored in `~/.claude/settings.json`:

```json
"memory-sync": {
  "cloudRoot": "/Users/chris/Google Drive/My Drive/claude-memory"
}
```

## Cross-Machine Setup

Run `/memory-sync-setup` on each machine, pointing to the same cloud root path. The path
encoding differs per machine but the cloud subdirectories are shared by convention.
