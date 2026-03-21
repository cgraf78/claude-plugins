#!/usr/bin/env bash
# sync-memory.sh — Symlink Claude Code project memory dirs to a cloud drive.
#
# Runs as a Claude Code Stop hook after every response. Designed to be
# essentially free in the common case: a pure-bash symlink check exits
# immediately when nothing needs doing.
#
# Config: ~/.claude/settings.json → pluginConfigs."memory-sync@cgraf78-claude-plugins".options.cloudRoot
#
# Path mapping:
#   Claude Code encodes absolute paths by replacing / with -.
#   This script strips the machine-specific $HOME prefix, leaving a
#   relative path that is stable across machines:
#
#     -Users-chris-git  →  <cloud-root>/git
#     -home-chris-git   →  <cloud-root>/git   (same dir on Linux)
#
# Caveat: directory names containing "-" are indistinguishable from path
# separators in the encoding. ~/my-project and ~/my/project both use "-"
# as separator. Works for typical structures; document if it bites you.

SETTINGS="$HOME/.claude/settings.json"
PROJECTS="$HOME/.claude/projects"

# --- Read config -----------------------------------------------------------

# Exit silently if settings file is missing or plugin is not configured.
[ -f "$SETTINGS" ] || exit 0
cloud_root=$(jq -r '.pluginConfigs["memory-sync@cgraf78-claude-plugins"].options.cloudRoot // empty' "$SETTINGS" 2>/dev/null) || exit 0
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

# Encode $HOME the same way Claude Code does: replace each / with -.
# e.g. /Users/chris → -Users-chris,  /home/chris → -home-chris
home_prefix="${HOME//\//-}"

for dir in "$PROJECTS"/*/; do
    [ -d "$dir" ] || continue

    # Strip trailing slash for consistent path construction.
    dir="${dir%/}"
    memory="$dir/memory"

    # Already symlinked — nothing to do.
    [ -L "$memory" ] && continue

    dir_name=$(basename "$dir")

    # Skip dirs that don't belong to this machine's home directory.
    # On a shared cloud drive, other machines' encoded dirs may be present.
    if [[ "$dir_name" != "$home_prefix" && "$dir_name" != "${home_prefix}-"* ]]; then
        continue
    fi

    # Derive relative path by stripping the home prefix.
    #   -Users-chris-git  →  strip -Users-chris  →  -git  →  strip -  →  git
    #   -Users-chris      →  strip -Users-chris  →  (empty)  →  maps to cloud root
    relative="${dir_name#"$home_prefix"}"   # strip home prefix
    relative="${relative#-}"                # strip leading dash
    relative="${relative//-//}"             # replace remaining - with /

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
    echo "memory-sync: linked $dir_name → $cloud_dir"
done
