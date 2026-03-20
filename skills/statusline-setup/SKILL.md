---
name: statusline-setup
description: Configure Claude Code to use the claude-statusline plugin. Edits ~/.claude/settings.json to add the statusLine command pointing at the installed script.
argument-hint: ""
allowed-tools: [Read, Edit, Write, Bash]
---

# statusline-setup

Configure the Claude Code status line to use this plugin.

## Steps

1. Read `~/.claude/plugins/installed_plugins.json` and find the entry whose name contains `claude-statusline`. Extract the `installPath`. If not found, tell the user the plugin does not appear to be installed and stop.

2. Derive the version-independent glob path from the install path by replacing the version component with `*`. For example, if the install path is `/Users/chris/.claude/plugins/cache/cgraf78-claude-plugins/claude-statusline/1.0.0`, the glob path is `~/.claude/plugins/cache/cgraf78-claude-plugins/claude-statusline/*/scripts/statusline.sh`. Verify the actual file exists at the install path.

3. Check whether `~/.claude/settings.json` exists.
   - If it does not exist, create it with the content `{}`.
   - Read the file and add or replace the `statusLine` key with:
     ```json
     "statusLine": {
       "type": "command",
       "command": "bash ~/.claude/plugins/cache/cgraf78-claude-plugins/claude-statusline/*/scripts/statusline.sh"
     }
     ```
   Use the glob path with `~` and `*` for the version — this survives plugin updates without reconfiguration.

4. Confirm to the user that the status line has been configured and will take effect immediately.
