---
name: memory-sync-setup
description: Configure Claude Code memory sync to a cloud drive. Writes the machine-specific cloud root path to pluginConfigs in ~/.claude/settings.local.json and installs a Stop hook in settings.json to keep symlinks current.
argument-hint: ""
allowed-tools: [Read, Edit, Write, Bash]
---

# memory-sync-setup

Configure Claude Code to sync project memory directories to a cloud drive, so memory
is shared across machines.

## Steps

1. Find the plugin install path by reading `~/.claude/plugins/installed_plugins.json`
   and locating the entry whose name is `memory-sync`. Extract the `installPath`.
   If not found, tell the user the plugin does not appear to be installed and stop.

2. Ask the user for the cloud root path — the directory on their cloud drive where
   memory should be stored. For example:
   - macOS iCloud: `~/Library/Mobile Documents/com~apple~CloudDocs/claude-memory`
   - Google Drive: `~/Google Drive/My Drive/claude-memory`
   - Dropbox: `~/Dropbox/claude-memory`

   Expand any `~` to the full home path before saving.

3. The cloud root path is machine-specific, so it goes in `~/.claude/settings.local.json`
   (not `settings.json`, which is typically synced across machines via dotfiles).

   Check whether `~/.claude/settings.local.json` exists.
   - If not, create it with content `{}`.

   Read the file and add or replace the `pluginConfigs` key, preserving all other content:

   **Plugin config** (use the `pluginConfigs` field — the correct place for plugin settings):
   ```json
   "pluginConfigs": {
     "memory-sync@cgraf78-claude-plugins": {
       "options": {
         "cloudRoot": "/full/expanded/path/to/cloud-memory"
       }
     }
   }
   ```

   If `pluginConfigs` already exists, add or replace only the `memory-sync@cgraf78-claude-plugins`
   key within it, preserving other plugin configs.

4. The Stop hook is generic and belongs in `~/.claude/settings.json`. Check whether
   `~/.claude/settings.json` exists.
   - If not, create it with content `{}`.

   Add the Stop hook to the existing `hooks.Stop` array, or create it:
   ```json
   "hooks": {
     "Stop": [
       {
         "hooks": [
           {
             "type": "command",
             "command": "bash ~/.claude/plugins/cache/cgraf78-claude-plugins/memory-sync/*/scripts/sync-memory.sh"
           }
         ],
         "matcher": ""
       }
     ]
   }
   ```

   Use `~` and `*` for the version in the command path — this survives plugin
   updates without reconfiguration. If a `Stop` array already exists, append the
   new hook entry rather than replacing the array.

5. Run the sync script once to wire up all existing project directories immediately:
   ```bash
   bash ~/.claude/plugins/cache/cgraf78-claude-plugins/memory-sync/*/scripts/sync-memory.sh
   ```

6. Show the user a summary: which cloud root was configured, which project directories
   were linked (if any output was produced by the script), and a reminder to run
   `/memory-sync-setup` on each other machine pointing to the same cloud root path.
