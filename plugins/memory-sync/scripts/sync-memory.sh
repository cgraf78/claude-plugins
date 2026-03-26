#!/usr/bin/env bash
# sync-memory — Symlink Claude Code project memory dirs to a cloud drive.
#
# Runs as a Claude Code Stop hook after every response. Designed to be
# essentially free in the common case: a pure-bash symlink check exits
# immediately when nothing needs doing.
#
# Config: ~/.claude/settings.local.json → pluginConfigs."memory-sync@cgraf78-claude-plugins".options.cloudRoot
#         Falls back to ~/.claude/settings.json if not found in local.
#
# Path mapping:
#   Reads the real cwd from session transcripts to get the actual project
#   path, then strips the machine-specific home prefix to derive a stable
#   cloud subdirectory that works across machines:
#
#     ~/git/my-project  →  <cloud-root>/git/my-project
#     ~/fbsource        →  <cloud-root>/fbsource       (same on any machine)

SETTINGS_LOCAL="$HOME/.claude/settings.local.json"
SETTINGS="$HOME/.claude/settings.json"
PROJECTS="$HOME/.claude/projects"
PLUGIN_KEY="memory-sync@cgraf78-claude-plugins"

# --- Read config -----------------------------------------------------------

# Try settings.local.json first (machine-specific), fall back to settings.json.
cloud_root=""
for cfg in "$SETTINGS_LOCAL" "$SETTINGS"; do
    [ -f "$cfg" ] || continue
    cloud_root=$(jq -r ".pluginConfigs[\"$PLUGIN_KEY\"].options.cloudRoot // empty" "$cfg" 2>/dev/null) && [ -n "$cloud_root" ] && break
done
[ -n "$cloud_root" ] || exit 0

# --- Fast path -------------------------------------------------------------
# Check whether all project memory dirs are already symlinks.
# Pure bash, no subprocesses. Exits immediately if nothing needs doing.

needs_work=0
for dir in "$PROJECTS"/*/; do
    [ -d "$dir" ] || continue
    [ -L "${dir%/}/memory" ] || { needs_work=1; break; }
done
[ "$needs_work" -eq 0 ] && exit 0

# --- Slow path -------------------------------------------------------------
# A new project directory appeared. Wire up any missing symlinks.

# Known path prefixes to strip when deriving the cloud subdirectory.
# Add additional prefixes here if your projects live outside $HOME.
known_prefixes=("$HOME")

for dir in "$PROJECTS"/*/; do
    [ -d "$dir" ] || continue

    # Strip trailing slash for consistent path construction.
    dir="${dir%/}"
    memory="$dir/memory"

    # Already symlinked — nothing to do.
    [ -L "$memory" ] && continue

    # --- Resolve the real project path from session transcripts ---
    # The encoded dir name is lossy (dashes are ambiguous), so we read
    # the cwd from session transcripts to get the real path. The first
    # line is often a snapshot record without cwd, so scan the first
    # few lines.
    real_path=""
    for transcript in "$dir"/*.jsonl; do
        [ -f "$transcript" ] || continue
        real_path=$(head -5 "$transcript" | jq -r 'select(.cwd != null) | .cwd' 2>/dev/null | head -1)
        [ -n "$real_path" ] && break
    done

    # Skip if we can't determine the real path.
    [ -n "$real_path" ] || continue

    # Strip known prefix to get relative path.
    relative=""
    matched=0
    for pfx in "${known_prefixes[@]}"; do
        if [[ "$real_path" == "$pfx" ]]; then
            matched=1
            break
        elif [[ "$real_path" == "$pfx/"* ]]; then
            relative="${real_path#"$pfx"/}"
            matched=1
            break
        fi
    done
    [ "$matched" -eq 1 ] || continue

    # Map to cloud subdirectory (home root maps directly to cloud root).
    if [ -z "$relative" ]; then
        cloud_dir="$cloud_root"
    else
        cloud_dir="$cloud_root/$relative"
    fi

    mkdir -p "$cloud_dir"

    # Migrate any existing local memory content to the cloud dir.
    # -n (no-clobber) avoids overwriting newer cloud content with stale local files.
    if [ -d "$memory" ]; then
        cp -rn "$memory/." "$cloud_dir/" 2>/dev/null || true
        rm -rf "$memory"
    fi

    ln -s "$cloud_dir" "$memory"
    echo "memory-sync: linked $(basename "$dir") → $cloud_dir"
done
