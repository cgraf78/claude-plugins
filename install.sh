#!/usr/bin/env bash
set -e

claude plugin marketplace add cgraf78/claude-plugins 2>/dev/null || true
claude plugin install claude-statusline
claude plugin install memory-sync
