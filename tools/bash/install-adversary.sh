#!/usr/bin/env bash
#
# install-adversary.sh -- Install the adversary review system globally.
#
# Installs three components to ~/.claude/ so they work in all projects:
#   1. adversary.md        -> ~/.claude/agents/       (subagent definition)
#   2. adversary-review.md -> ~/.claude/commands/      (/adversary-review slash command)
#   3. adversary-check.sh  -> ~/.claude/hooks/         (mechanical verification script)
#
# Run from the repo root:
#   bash tools/bash/install-adversary.sh
#
# The PostToolUse hook (auto-run after Write/Edit) requires a manual settings.json
# edit -- see instructions printed at the end.

set -euo pipefail

# Resolve repo root (script is at tools/bash/install-adversary.sh)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CLAUDE_DIR="$HOME/.claude"

# --- Verify source files exist ---
AGENT_SRC="$REPO_ROOT/.claude/agents/adversary.md"
COMMAND_SRC="$REPO_ROOT/.claude/commands/adversary-review.md"
SCRIPT_SRC="$REPO_ROOT/tools/bash/adversary-check.sh"

for f in "$AGENT_SRC" "$COMMAND_SRC" "$SCRIPT_SRC"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: Source file not found: $f"
        echo "Are you running this from the claude-tools-library repo root?"
        exit 1
    fi
done

# --- Create directories ---
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/hooks"

# --- Copy files ---
cp "$AGENT_SRC" "$CLAUDE_DIR/agents/adversary.md"
echo "Installed: ~/.claude/agents/adversary.md"

cp "$COMMAND_SRC" "$CLAUDE_DIR/commands/adversary-review.md"
echo "Installed: ~/.claude/commands/adversary-review.md"

cp "$SCRIPT_SRC" "$CLAUDE_DIR/hooks/adversary-check.sh"
chmod +x "$CLAUDE_DIR/hooks/adversary-check.sh"
echo "Installed: ~/.claude/hooks/adversary-check.sh"

echo ""
echo "Done. Three components installed globally."
echo ""
echo "=== Optional: PostToolUse hook ==="
echo ""
echo "To auto-run adversary-check.sh after every Write/Edit, add this to"
echo "your ~/.claude/settings.json (merge with existing hooks if any):"
echo ""
echo '  "hooks": {'
echo '    "PostToolUse": ['
echo '      {'
echo '        "matcher": "Write|Edit",'
echo '        "hooks": ['
echo '          {'
echo '            "type": "command",'
echo "            \"command\": \"bash $CLAUDE_DIR/hooks/adversary-check.sh . 2>/dev/null || true\""
echo '          }'
echo '        ]'
echo '      }'
echo '    ]'
echo '  }'
echo ""
