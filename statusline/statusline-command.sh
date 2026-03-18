#!/usr/bin/env bash
# Claude Code status line: context usage display

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

if [ -z "$used" ]; then
  printf "%s | Context: no messages yet | Window: %s tokens" "$cwd" "$window_size"
else
  used_int=${used%.*}
  if [ "$used_int" -ge 90 ]; then
    color="\033[0;31m"   # red
  elif [ "$used_int" -ge 70 ]; then
    color="\033[0;33m"   # yellow
  else
    color="\033[0;32m"   # green
  fi
  reset="\033[0m"

  printf "%s | ${color}Context: %s%% used (%s%% remaining)${reset} | In: %s  Out: %s  Window: %s" \
    "$cwd" "$used" "$remaining" "$total_input" "$total_output" "$window_size"
fi
