#!/usr/bin/env bash
set -e

# Add marketplace if not already registered, otherwise update it to get latest plugin versions.
claude plugin marketplace add cgraf78/claude-plugins 2>/dev/null || \
    claude plugin marketplace update cgraf78-claude-plugins

# Install or update each plugin.
# `claude plugin install` installs if missing; `claude plugin update` upgrades if already installed.
# Running both handles all cases: fresh install, re-run, and version bumps.
for plugin in status-line memory-sync; do
    claude plugin install "$plugin" 2>/dev/null || \
        claude plugin update "$plugin"
done
