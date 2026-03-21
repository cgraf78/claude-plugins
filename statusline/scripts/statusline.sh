#!/usr/bin/env bash
# Claude Code status line.
# Format: hostname | path (branch flags) | 🤖 model | 🧠 ctx% | 💰 $cost | 💬 N turns

export LC_NUMERIC=C
input=$(cat)

# ANSI colors
BOLD_CYAN='\033[1;36m'
GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
YELLOW='\033[0;33m'
ORANGE='\033[38;5;208m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
FAST_ORANGE='\033[38;2;255;120;20m'
RESET='\033[0m'
SEP=' | '

# Extract values (single jq call)
{
    read -r cwd
    read -r model_id
    read -r used
    read -r total_cost
    read -r transcript
} < <(printf '%s' "$input" | jq -r '
    .workspace.current_dir // .cwd // "",
    .model.id // "",
    .context_window.used_percentage // "",
    .cost.total_cost_usd // "",
    .transcript_path // ""
')

# Short model name (strip claude- prefix and date suffix)
model=""
if [ -n "$model_id" ]; then
    model=$(echo "$model_id" | sed -E '
        s/^claude-//
        s/-[0-9]{8}$//
        s/^([0-9]+)-([0-9]+)-(.+)$/\3-\1.\2/
        s/^([0-9]+)-([^0-9].*)$/\2-\1/
        s/^([^0-9].*)-([0-9]+)-([0-9]+)$/\1-\2.\3/
    ')
fi

# Fast mode
fast_mode=$(jq -r '.fastMode // false' ~/.claude/settings.json 2>/dev/null)

# Hostname (bash builtin, no fork)
host="${HOSTNAME%%.*}"

# Directory (replace $HOME with ~)
dir="?"
if [ -n "$cwd" ]; then
    dir="${cwd/#$HOME/\~}"
fi

# Git branch + dirty flags
branch_part=""
if [ -n "$cwd" ] && command -v git >/dev/null 2>&1; then
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
             || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        flags=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | awk '
            /^[MADRC]/  { staged=1 }
            /^.[MDRC]/  { unstaged=1 }
            /^\?\?/     { untracked=1 }
            END { if(staged) printf "+"; if(unstaged) printf "*"; if(untracked) printf "%%" }
        ')
        [ -n "$flags" ] && flags=" $flags"
        branch_part=" (${branch}${flags})"
    fi
fi

# Context percentage with color
ctx_color="$GREEN"
if [ -n "$used" ]; then
    ctx_int=$(printf "%.0f" "$used" 2>/dev/null || echo "0")
    if [ "$ctx_int" -ge 85 ]; then
        ctx_color="$RED"
    elif [ "$ctx_int" -ge 66 ]; then
        ctx_color="$ORANGE"
    elif [ "$ctx_int" -ge 33 ]; then
        ctx_color="$YELLOW"
    fi
fi

# Cost (prefer native total_cost_usd, fall back to token math)
cost_fmt=""
if [ -n "$total_cost" ] && [ "$total_cost" != "null" ] && [ "$total_cost" != "0" ]; then
    cost_fmt=$(printf "%.2f" "$total_cost" 2>/dev/null || echo "0.00")
else
    {
        read -r total_in
        read -r total_out
        read -r cache_write
        read -r cache_read
    } < <(printf '%s' "$input" | jq -r '
        .context_window.total_input_tokens // 0,
        .context_window.total_output_tokens // 0,
        .context_window.current_usage.cache_creation_input_tokens // 0,
        .context_window.current_usage.cache_read_input_tokens // 0
    ')
    if [ "$total_in" -gt 0 ] 2>/dev/null || [ "$total_out" -gt 0 ] 2>/dev/null; then
        cost_fmt=$(awk -v id="$model_id" \
                       -v tin="$total_in" -v tout="$total_out" \
                       -v cw="$cache_write" -v cr="$cache_read" '
        BEGIN {
            if      (id ~ /opus/)   { pin=15;   pcw=18.75; pcr=1.50; pout=75  }
            else if (id ~ /haiku/)  { pin=0.80; pcw=1;     pcr=0.08; pout=4   }
            else                    { pin=3;    pcw=3.75;  pcr=0.30; pout=15  }
            cost = (tin * pin + cw * pcw + cr * pcr + tout * pout) / 1000000
            printf "%.2f", cost
        }')
    fi
fi

# Transcript: turn count + session name (single pass)
turn_count=""
session_name=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    turn_count=$(jq 'select(.type == "user") | select(
        (.message.content | type) == "string" and
        (.message.content | startswith("<local-command") | not) and
        (.message.content | startswith("<command-name>") | not)
    )' "$transcript" 2>/dev/null | grep -c '^{' || echo "0")
    session_name=$(tac "$transcript" 2>/dev/null \
        | grep -m1 '^{"type":"custom-title"' \
        | jq -r '.customTitle // empty')
fi

# Build status line
LINE="${BOLD_CYAN}${host}${RESET}"
LINE="${LINE}${SEP}${GREEN}${dir}${BRIGHT_GREEN}${branch_part}${RESET}"

if [ -n "$session_name" ]; then
    LINE="${LINE}${SEP}${BOLD_CYAN}⚡${session_name}${RESET}"
fi

if [ -n "$model" ]; then
    if [ "$fast_mode" = "true" ]; then
        LINE="${LINE}${SEP}${MAGENTA}🤖 ${model} ${FAST_ORANGE}↯fast${RESET}"
    else
        LINE="${LINE}${SEP}${MAGENTA}🤖 ${model}${RESET}"
    fi
fi

if [ -n "$used" ]; then
    LINE="${LINE}${SEP}${ctx_color}🧠 ${ctx_int}%${RESET}"
fi

if [ -n "$cost_fmt" ]; then
    LINE="${LINE}${SEP}${YELLOW}💰 \$${cost_fmt}${RESET}"
fi

if [ -n "$turn_count" ] && [ "$turn_count" != "0" ]; then
    LINE="${LINE}${SEP}${MAGENTA}💬 ${turn_count} turns${RESET}"
fi

echo -e "$LINE" | tr -d '\r' | head -1
