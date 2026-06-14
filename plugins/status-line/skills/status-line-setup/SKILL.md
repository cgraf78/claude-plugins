---
name: status-line-setup
description: Configure Claude Code to use the status-line plugin. Edits ~/.claude/settings.json to add the statusLine command pointing at the installed script.
argument-hint: ""
allowed-tools: [Read, Edit, Write, Bash]
---

# status-line-setup

Configure the Claude Code status line to use this plugin.

## Steps

1. Read `~/.claude/plugins/installed_plugins.json` and find the entry whose `name` is `status-line` to confirm the plugin is installed. If not found, tell the user the plugin does not appear to be installed and stop.

2. The script lives at the version-independent glob path `~/.claude/plugins/cache/cgraf78-claude-plugins/status-line/*/scripts/status-line.sh` (the `*` matches whatever version is installed, so the config survives plugin updates). Verify a file matches that glob.

3. Check whether `~/.claude/settings.json` exists.
   - If it does not exist, create it with the content `{}`.
   - Read the file and add or replace the `statusLine` key with:
     ```json
     "statusLine": {
       "type": "command",
       "command": "bash ~/.claude/plugins/cache/cgraf78-claude-plugins/status-line/*/scripts/status-line.sh"
     }
     ```
   Use the glob path with `~` and `*` for the version — this survives plugin updates without reconfiguration.

4. Confirm to the user that the status line has been configured and will take effect immediately.
