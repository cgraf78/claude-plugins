# status-line

A rich status line for Claude Code showing:

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

## Requirements

- `bash`
- `jq`
- `git` (optional, for branch display)

## Setup

After installing, run `/status-line-setup` in any Claude Code session to configure your `~/.claude/settings.json`.
