# status-line

A rich status line for Claude Code showing:

```text
hostname | ~/path/to/dir (branch +*%) | ⚡my-session | 🤖 sonnet-4.6 | 🧠 42% | 💰 $0.08 | 💬 12 turns
```

- **Host** — machine name
- **Directory** — current working dir with `~` abbreviation
- **Git** — branch name with dirty flags (`+` staged, `*` unstaged, `%` untracked)
- **Session name** — shown when the session has a custom title, such as one set with `/rename` (⚡)
- **Model** — short model name, with fast mode indicator (↯fast)
- **Context** — usage percentage, color-coded green → yellow → orange → red
- **Cost** — cumulative session cost in USD
- **Turns** — number of user turns in the conversation

## Requirements

- `bash`
- `jq`
- `git` (optional, for branch display)

## Setup

After installing, run `/status-line-setup` in any Claude Code session to configure your `~/.claude/settings.json`.

## Configuration

- `CLAUDE_STATUS_LINE_CACHE_TTL_SECONDS` — how many seconds a cached git branch and dirty-flag result is reused for the same directory (default `2`; empty or non-integer values fall back to `2`).
- Cache directory — `$XDG_CACHE_HOME/claude-status-line`, falling back to `~/.cache/claude-status-line`, created owner-only. It holds the git cache and a per-transcript turn-count/session-name cache that is revalidated against the transcript file rather than the TTL. It is safe to delete.
