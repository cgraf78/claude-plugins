# claude-plugins

![Tests](https://github.com/cgraf78/claude-plugins/actions/workflows/test.yml/badge.svg?branch=main)

A [Claude Code](https://claude.ai/code) plugin marketplace. Today it holds one
plugin, [status-line](./plugins/status-line/), a rich status line:

```text
hostname | ~/path/to/dir (branch +*%) | ⚡my-session | 🤖 sonnet-4.6 | 🧠 42% | 💰 $0.08 | 💬 12 turns
```

It shows the host, directory, git branch with dirty flags, session name,
model, color-coded context usage, session cost, and turn count. It needs
`bash` and `jq`; `git` is optional, for the branch.

## Getting started

In a Claude Code session:

```text
/plugin marketplace add cgraf78/claude-plugins
/plugin install status-line@cgraf78-claude-plugins
```

Then run the plugin's `status-line-setup` skill (type `/status-line-setup`;
Claude Code may list it as `/status-line:status-line-setup`). It adds the
`statusLine` command to `~/.claude/settings.json`; installing the plugin alone
does not change your status line.

Or install and refresh every plugin in this marketplace from a shell, then run
the setup skill as above:

```sh
curl -fsSL https://raw.githubusercontent.com/cgraf78/claude-plugins/main/install.sh | bash
```

The script needs `curl`, `jq`, and the `claude` CLI on `PATH`. It runs
`claude plugin marketplace add`/`update`, then `claude plugin install` and
`update` for each plugin. It ignores errors from the individual `claude plugin`
commands, so check `/plugin` afterwards if something looks missing.

## Plugins

- [status-line](./plugins/status-line/) — Rich status line showing host, directory, git, session name, model, context, cost, and turns

## License

MIT. See [`LICENSE`](LICENSE).
