#!/usr/bin/env bash
set -e

claude plugin marketplace add cgraf78/claude-plugins 2>/dev/null || \
    claude plugin marketplace update cgraf78-claude-plugins
claude plugin install status-line
claude plugin install memory-sync
