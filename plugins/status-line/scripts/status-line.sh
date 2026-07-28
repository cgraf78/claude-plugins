#!/usr/bin/env bash
# Claude Code status line.
# Format: hostname | path (branch flags) | 🤖 model | 🧠 ctx% | 💰 $cost | 💬 N turns

export LC_NUMERIC=C
input=$(cat)

status_cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/claude-status-line"
status_cache_ttl="${CLAUDE_STATUS_LINE_CACHE_TTL_SECONDS:-2}"
case "$status_cache_ttl" in
  '' | *[!0-9]*) status_cache_ttl=2 ;;
esac

_status_cache_prepare() {
  local old_umask

  if [ ! -d "$status_cache_root" ]; then
    old_umask=$(umask)
    umask 077
    mkdir -p "$status_cache_root" 2>/dev/null || true
    umask "$old_umask"
  fi
  [ -d "$status_cache_root" ] && [ -w "$status_cache_root" ]
}

_status_cache_key() {
  local _rest

  read -r REPLY _rest < <(printf '%s' "$1" | cksum) || return 1
  [ -n "$REPLY" ]
}

_status_cache_write() {
  local file="$1" tmp old_umask
  shift

  old_umask=$(umask)
  umask 077
  tmp=$(mktemp "${file}.tmp.XXXXXX" 2>/dev/null) || {
    umask "$old_umask"
    return 1
  }
  if ! printf '%s\n' "$@" >"$tmp" 2>/dev/null; then
    umask "$old_umask"
    rm -f "$tmp" 2>/dev/null || true
    return 1
  fi
  umask "$old_umask"
  mv -f "$tmp" "$file" 2>/dev/null || {
    rm -f "$tmp" 2>/dev/null || true
    return 1
  }
}

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

# Fast mode follows Claude's settings precedence: machine-local settings may
# override synced global settings without making the plugin depend on dotfiles.
fast_mode=false
for cfg in "$HOME/.claude/settings.local.json" "$HOME/.claude/settings.json"; do
  [ -f "$cfg" ] || continue
  value=$(jq -r 'if has("fastMode") then .fastMode else empty end' "$cfg" 2>/dev/null)
  if [ -n "$value" ]; then
    fast_mode="$value"
    break
  fi
done

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
  git_cache_hit=0
  git_cache_file=""
  if _status_cache_prepare && _status_cache_key "git:$cwd"; then
    git_cache_file="$status_cache_root/git-v1-$REPLY"
    if [ -r "$git_cache_file" ]; then
      {
        IFS= read -r git_cached_at || git_cached_at=""
        IFS= read -r git_cached_cwd || git_cached_cwd=""
        IFS= read -r git_cached_branch || git_cached_branch=""
      } <"$git_cache_file"
      git_now=$(date +%s)
      case "$git_cached_at:$git_now" in
        *[!0-9:]* | :* | *:) ;;
        *)
          if [ "$git_cached_cwd" = "$cwd" ] &&
            [ $((git_now - git_cached_at)) -ge 0 ] &&
            [ $((git_now - git_cached_at)) -le "$status_cache_ttl" ]; then
            branch_part="$git_cached_branch"
            git_cache_hit=1
          fi
          ;;
      esac
    fi
  fi

  if [ "$git_cache_hit" -eq 0 ]; then
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null ||
      git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
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
    if [ -n "$git_cache_file" ]; then
      git_now=$(date +%s)
      _status_cache_write "$git_cache_file" "$git_now" "$cwd" "$branch_part" || true
    fi
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
            # Fallback per-model prices in USD per million tokens
            # (input / cache-write / cache-read / output), used only when the
            # runtime did not supply cost.total_cost_usd. Estimates that will
            # drift from published Anthropic pricing over time.
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
  transcript_cache_hit=0
  transcript_cache_file=""
  transcript_meta=""
  transcript_size=""
  if transcript_meta=$(stat -L -c '%d:%i:%s:%Y' "$transcript" 2>/dev/null); then
    :
  elif transcript_meta=$(stat -L -f '%d:%i:%z:%m' "$transcript" 2>/dev/null); then
    :
  else
    transcript_meta=""
  fi
  transcript_size=$(wc -c <"$transcript" 2>/dev/null) || transcript_size=""
  transcript_size="${transcript_size//[[:space:]]/}"
  case "$transcript_size" in
    '' | *[!0-9]*) transcript_meta="" ;;
    *) transcript_meta="${transcript_meta}:${transcript_size}" ;;
  esac

  if [ -n "$transcript_meta" ] && _status_cache_prepare &&
    _status_cache_key "transcript:$transcript"; then
    transcript_cache_file="$status_cache_root/transcript-v1-$REPLY"
    if [ -r "$transcript_cache_file" ]; then
      {
        IFS= read -r transcript_cached_meta || transcript_cached_meta=""
        IFS= read -r transcript_cached_path || transcript_cached_path=""
        IFS= read -r transcript_cached_turns || transcript_cached_turns=""
        IFS= read -r transcript_cached_title || transcript_cached_title=""
      } <"$transcript_cache_file"
      if [ "$transcript_cached_meta" = "$transcript_meta" ] &&
        [ "$transcript_cached_path" = "$transcript" ]; then
        turn_count="$transcript_cached_turns"
        session_name="$transcript_cached_title"
        transcript_cache_hit=1
      fi
    fi
  fi

  if [ "$transcript_cache_hit" -eq 0 ]; then
    transcript_summary=$(jq -Rrn '
      reduce (inputs | fromjson?) as $entry (
        {turns: 0, title: ""};
        if ($entry.type == "user" and
            ($entry.message.content | type) == "string" and
            ($entry.message.content | startswith("<local-command") | not) and
            ($entry.message.content | startswith("<command-name>") | not)) then
          .turns += 1
        elif $entry.type == "custom-title" then
          .title = ($entry.customTitle // "")
        else
          .
        end
      )
      | [.turns, (.title | gsub("[\\t\\r\\n]"; " "))]
      | @tsv
    ' "$transcript" 2>/dev/null) || transcript_summary=""
    IFS=$'\t' read -r turn_count session_name <<<"$transcript_summary"
    case "$turn_count" in
      '' | *[!0-9]*) turn_count="" ;;
    esac
    if [ -n "$transcript_cache_file" ] && [ -n "$turn_count" ]; then
      _status_cache_write "$transcript_cache_file" \
        "$transcript_meta" "$transcript" "$turn_count" "$session_name" || true
    fi
  fi
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
