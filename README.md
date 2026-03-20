# claude-plugins

A collection of [Claude Code](https://claude.ai/code) plugins.

## Getting started

```sh
curl -fsSL https://raw.githubusercontent.com/cgraf78/claude-plugins/main/install.sh | bash
```

Then follow the plugin-specific setup below.

---

## claude-statusline

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

### Setup

After installing, run `/statusline-setup` in any Claude Code session to configure your `~/.claude/settings.json`.

## Requirements

- `bash`
- `jq`
- `git` (optional, for branch display)

## Manual setup

If you prefer to configure manually, add this to `~/.claude/settings.json`:

```json
"statusLine": {
  "type": "command",
  "command": "bash ~/.claude/plugins/cache/cgraf78/claude-statusline/1.0.0/scripts/statusline.sh"
}
```

## License

MIT
