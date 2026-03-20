---
name: statusline-setup
description: Configure Claude Code to use the claude-statusline plugin. Edits ~/.claude/settings.json to add the statusLine command pointing at the installed script.
argument-hint: ""
allowed-tools: [Read, Edit, Write, Bash]
---

# statusline-setup

Configure the Claude Code status line to use this plugin.

## Steps

1. Read `~/.claude/plugins/installed_plugins.json` and find the `installPath` for the plugin whose name contains `claude-statusline`. If not found, tell the user the plugin does not appear to be installed and stop.

2. The statusline script is at `<installPath>/scripts/statusline.sh`. Verify the file exists.

3. Check whether `~/.claude/settings.json` exists.
   - If it does not exist, create it with the content `{}`.
   - Read the file and add or replace the `statusLine` key with:
     ```json
     "statusLine": {
       "type": "command",
       "command": "bash <installPath>/scripts/statusline.sh"
     }
     ```
   Use the actual absolute install path — do not use environment variables or `~`.

4. Confirm to the user that the status line has been configured and will take effect immediately.
