---
name: status-line-setup
description: Configure Claude Code to use the status-line plugin. Edits ~/.claude/settings.json to add the statusLine command pointing at the installed script.
argument-hint: ""
allowed-tools: [Read, Edit, Write, Bash]
---

# status-line-setup

Configure the Claude Code status line to use this plugin.

## Steps

1. Read `~/.claude/plugins/installed_plugins.json`. Installed plugins live under its top-level `plugins` object, keyed as `<plugin>@<marketplace>`; find the `status-line@cgraf78-claude-plugins` key (its value is an array with one install record per scope, such as `user` or `project`) to confirm the plugin is installed. If not found, tell the user the plugin does not appear to be installed and stop.

2. The script lives at `<installPath>/scripts/status-line.sh`, where `installPath` comes from the `user`-scope record, or the first record when there is no `user` one (the same record the command below resolves; for example `~/.claude/plugins/cache/cgraf78-claude-plugins/status-line/<version>`). Verify the script exists there. Do not use a `status-line/*/scripts/status-line.sh` glob: when more than one version is cached, bash expands every match and runs the lexically first one, which can be an older version.

3. Check whether `~/.claude/settings.json` exists.
   - If it does not exist, create it with the content `{}`.
   - Read the file and add or replace the `statusLine` key with:
     ```json
     "statusLine": {
       "type": "command",
       "command": "bash \"$(jq -r '.plugins[\"status-line@cgraf78-claude-plugins\"] | (map(select(.scope == \"user\"))[0] // .[0]).installPath' ~/.claude/plugins/installed_plugins.json)/scripts/status-line.sh\""
     }
     ```
   The command resolves `installPath` from `installed_plugins.json` on each render, so it follows the recorded install across plugin updates without reconfiguration. It needs `jq`, which the script already requires. If the plugin entry or `jq` is missing, the command fails and the status line is blank; reinstalling the plugin or `jq` restores it.

4. Confirm to the user that the status line has been configured and will take effect immediately.
