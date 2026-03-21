#!/usr/bin/env bash
set -e

# Add marketplace if not already registered, then always update to get latest plugin versions.
claude plugin marketplace add cgraf78/claude-plugins 2>/dev/null || true
claude plugin marketplace update cgraf78-claude-plugins

# Discover plugins from marketplace.json — works for both curl-pipe and local execution.
plugins=$(curl -fsSL \
    "https://raw.githubusercontent.com/cgraf78/claude-plugins/main/.claude-plugin/marketplace.json" \
    | jq -r '.plugins[].name')

# Install or update each plugin.
# `claude plugin install` installs if missing; `claude plugin update` upgrades if already installed.
# Running both handles all cases: fresh install, re-run, and version bumps.
for plugin in $plugins; do
    claude plugin install "$plugin" 2>/dev/null || \
        claude plugin update "$plugin"
done
