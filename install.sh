#!/usr/bin/env bash

# Register marketplace if not already, then update to get latest plugin versions.
# Update failure (e.g. network blip) is non-fatal — cached versions will be used.
claude plugin marketplace add cgraf78/claude-plugins 2>/dev/null || true
claude plugin marketplace update cgraf78-claude-plugins || true

# Discover plugins dynamically from marketplace.json.
# Abort if this fails — there's nothing useful to do without the plugin list.
plugins=$(curl -fsSL \
    "https://raw.githubusercontent.com/cgraf78/claude-plugins/main/.claude-plugin/marketplace.json" \
    | jq -r '.plugins[].name') || { echo "error: failed to fetch marketplace.json" >&2; exit 1; }

# Install then update each plugin. Running both unconditionally handles all
# cases: fresh install, re-run at same version, and version bumps.
for plugin in $plugins; do
    claude plugin install "$plugin" 2>/dev/null || true
    claude plugin update  "$plugin" 2>/dev/null || true
done
