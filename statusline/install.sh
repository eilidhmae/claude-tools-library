#!/usr/bin/env bash
# Install the Claude Code statusline into ~/.claude
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude"

cp "$SCRIPT_DIR/statusline-command.sh" "$DEST/statusline-command.sh"
chmod +x "$DEST/statusline-command.sh"

# Merge statusLine config into ~/.claude/settings.json
SETTINGS="$DEST/settings.json"
if [ -f "$SETTINGS" ]; then
  # Merge: add/overwrite the statusLine key, preserve everything else
  tmp=$(mktemp)
  jq -s '.[0] * .[1]' "$SETTINGS" "$SCRIPT_DIR/settings.json" > "$tmp"
  mv "$tmp" "$SETTINGS"
else
  cp "$SCRIPT_DIR/settings.json" "$SETTINGS"
fi

echo "Statusline installed. Restart Claude Code to activate."
