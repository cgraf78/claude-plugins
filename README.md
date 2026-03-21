# claude-plugins

A collection of [Claude Code](https://claude.ai/code) plugins.

## Getting started

```sh
curl -fsSL https://raw.githubusercontent.com/cgraf78/claude-plugins/main/install.sh | bash
```

---

## status-line

A rich status line showing:

```
hostname | ~/path/to/dir (branch +*%) | 🤖 sonnet-4.6 | 🧠 42% | 💰 $0.08 | 💬 12 turns
```

- **Host** — machine name
- **Directory** — current working dir with `~` abbreviation
- **Git** — branch name with dirty flags (`+` staged, `*` unstaged, `%` untracked)
- **Session name** — shown when Claude has named the session (⚡)
- **Model** — short model name, with fast mode indicator (↯fast)
- **Context** — usage percentage, color-coded green → yellow → orange → red
- **Cost** — cumulative session cost in USD
- **Turns** — number of user turns in the conversation

### Requirements

- `bash`
- `jq`
- `git` (optional, for branch display)

### Setup

After installing, run `/status-line-setup` in any Claude Code session to configure your `~/.claude/settings.json`.

---

## memory-sync

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

### Requirements

- `bash`
- `jq`
- A cloud drive (Google Drive, Dropbox, iCloud, etc.)

### Setup

After installing, run `/memory-sync-setup` in any Claude Code session. Repeat on each
machine, pointing to the same cloud root path.

## License

MIT
