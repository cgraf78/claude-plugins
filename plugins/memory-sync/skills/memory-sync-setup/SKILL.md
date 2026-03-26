---
name: memory-sync-setup
description: Configure Claude Code memory sync to a cloud drive for cross-machine sharing.
argument-hint: ""
allowed-tools: [Read, Edit, Write, Bash]
---

# memory-sync-setup

Configure Claude Code to sync project memory directories to a cloud drive, so memory
is shared across machines.

## How it works

Each `~/.claude/projects/*/memory/` directory is replaced with a symlink pointing to a
consistent subdirectory on your cloud drive. The script reads the real project path from
session transcripts (not the lossy encoded dir name), then strips the machine-specific
home prefix:

```
~/git/my-project  →  <cloud-root>/git/my-project
~/fbsource        →  <cloud-root>/fbsource       (same on any machine)
```

A `Stop` hook runs after every response to catch newly created project directories.

## Steps

1. Find the plugin install path by reading `~/.claude/plugins/installed_plugins.json`
   and locating the entry whose name is `memory-sync`. Extract the `installPath`.
   If not found, tell the user the plugin does not appear to be installed and stop.

2. Ask the user for the cloud root path — the directory on their cloud drive where
   memory should be stored. For example:
   - macOS Google Drive: `~/Library/CloudStorage/GoogleDrive-<account>/My Drive/claude-memory`
   - Linux Google Drive: `~/gdrive/claude-memory` (if mounted via rclone/mclone)
   - macOS iCloud: `~/Library/Mobile Documents/com~apple~CloudDocs/claude-memory`
   - Dropbox: `~/Dropbox/claude-memory`
   - Windows Google Drive: `G:\My Drive\claude-memory`

   Expand any `~` to the full home path before saving.

3. The cloud root path is machine-specific, so it goes in `~/.claude/settings.local.json`
   (not `settings.json`, which is typically synced across machines via dotfiles).

   Check whether `~/.claude/settings.local.json` exists.
   - If not, create it with content `{}`.

   Read the file and add or replace the config, preserving all other content:

   ```json
   "pluginConfigs": {
     "memory-sync@cgraf78-claude-plugins": {
       "options": {
         "cloudRoot": "/full/expanded/path/to/cloud-memory"
       }
     }
   }
   ```

   If `pluginConfigs` already exists, add or replace only the
   `memory-sync@cgraf78-claude-plugins` key within it, preserving other plugin configs.

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

   Use `*` for the version in the command path — this survives plugin updates
   without reconfiguration. If a `Stop` array already exists, append the new
   hook entry rather than replacing the array. If a memory-sync hook already
   exists (command contains "sync-memory"), skip this step.

5. Create the cloud root directory if it doesn't exist:
   ```bash
   mkdir -p "<cloud-root>"
   ```

6. Run the sync script once to wire up all existing project directories immediately:
   ```bash
   bash ~/.claude/plugins/cache/cgraf78-claude-plugins/memory-sync/*/scripts/sync-memory.sh
   ```

7. Show the user a summary: which cloud root was configured, which project directories
   were linked (if any output was produced by the script), and a reminder to run
   `/memory-sync-setup` on each other machine pointing to the same cloud root path.
