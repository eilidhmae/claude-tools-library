#!/usr/bin/env bash
#
# install-agents.sh -- Install the orchestrator/manager/adversary agent system.
#
# Installs six files to either a global location (~/.claude/) or the current
# project's .claude/ directory:
#
#   agents/adversary.md       -- Adversarial-reviewer subagent definition
#   agents/manager.md         -- Manager subagent definition
#   agents/orchestrator.md    -- Orchestrator subagent definition
#   agents/_shared.md         -- Rules shared across all three agents
#   commands/adversary-review.md -- /adversary-review slash command
#   hooks/adversary-check.sh  -- Mechanical verification script (chmod +x)
#
# Usage:
#   bash tools/bash/install-agents.sh            # install globally to ~/.claude/
#   bash tools/bash/install-agents.sh --local    # install into ./.claude/ of CWD
#   bash tools/bash/install-agents.sh --project  # alias for --local
#
# The PostToolUse hook (auto-run after Write/Edit) requires a manual
# settings.json edit -- see instructions printed at the end.

set -euo pipefail

# --- Parse args ---
TARGET_MODE="global"
FORCE=0
for arg in "$@"; do
    case "$arg" in
        --local|--project)
            TARGET_MODE="local"
            ;;
        -f|--force|-y|--yes)
            FORCE=1
            ;;
        -h|--help)
            sed -n '2,22p' "$0"
            exit 0
            ;;
        *)
            echo "ERROR: Unknown argument: $arg" >&2
            echo "Usage: install-agents.sh [--local] [--force]" >&2
            exit 1
            ;;
    esac
done

# Resolve repo root (script is at tools/bash/install-agents.sh)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- Verify source files exist ---
AGENT_ADV_SRC="$REPO_ROOT/.claude/agents/adversary.md"
AGENT_MGR_SRC="$REPO_ROOT/.claude/agents/manager.md"
AGENT_ORC_SRC="$REPO_ROOT/.claude/agents/orchestrator.md"
AGENT_SHARED_SRC="$REPO_ROOT/.claude/agents/_shared.md"
COMMAND_SRC="$REPO_ROOT/.claude/commands/adversary-review.md"
SCRIPT_SRC="$REPO_ROOT/tools/bash/adversary-check.sh"

for f in "$AGENT_ADV_SRC" "$AGENT_MGR_SRC" "$AGENT_ORC_SRC" \
         "$AGENT_SHARED_SRC" "$COMMAND_SRC" "$SCRIPT_SRC"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: Source file not found: $f" >&2
        echo "Are you running this from the claude-tools-library repo root?" >&2
        exit 1
    fi
done

# --- Resolve install target ---
if [ "$TARGET_MODE" = "local" ]; then
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "ERROR: --local requires the current directory to be inside a git repo." >&2
        echo "       CWD: $(pwd)" >&2
        exit 1
    fi
    CLAUDE_DIR="$(pwd)/.claude"
    HOOK_PATH_DISPLAY="\$(pwd)/.claude/hooks/adversary-check.sh"
else
    CLAUDE_DIR="$HOME/.claude"
    HOOK_PATH_DISPLAY="$CLAUDE_DIR/hooks/adversary-check.sh"
fi

# --- Overwrite confirmation (local mode only) ---
if [ "$TARGET_MODE" = "local" ] && [ -d "$CLAUDE_DIR/agents" ]; then
    EXISTING=$(find "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/hooks" \
                    -maxdepth 1 -type f 2>/dev/null | head -1 || true)
    if [ -n "$EXISTING" ] && [ "$FORCE" -ne 1 ]; then
        if [ ! -t 0 ]; then
            echo "ERROR: $CLAUDE_DIR/ already contains agent files and stdin is not a TTY." >&2
            echo "       Re-run with --force to overwrite non-interactively." >&2
            exit 1
        fi
        echo "Target $CLAUDE_DIR/ already contains agent files."
        printf "Overwrite existing files? [y/N]: "
        read -r REPLY
        case "$REPLY" in
            y|Y|yes|YES) ;;
            *)
                echo "Aborted."
                exit 0
                ;;
        esac
    fi
fi

# --- Create directories ---
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/hooks"

# --- Copy files (overwrites any existing install) ---
install_file() {
    local src="$1"
    local dest="$2"
    local label
    if [ -e "$dest" ]; then
        label="Updated"
    else
        label="Installed"
    fi
    cp -f "$src" "$dest"
    echo "$label: $dest"
}

install_file "$AGENT_ADV_SRC"    "$CLAUDE_DIR/agents/adversary.md"
install_file "$AGENT_MGR_SRC"    "$CLAUDE_DIR/agents/manager.md"
install_file "$AGENT_ORC_SRC"    "$CLAUDE_DIR/agents/orchestrator.md"
install_file "$AGENT_SHARED_SRC" "$CLAUDE_DIR/agents/_shared.md"
install_file "$COMMAND_SRC"      "$CLAUDE_DIR/commands/adversary-review.md"
install_file "$SCRIPT_SRC"       "$CLAUDE_DIR/hooks/adversary-check.sh"
chmod +x "$CLAUDE_DIR/hooks/adversary-check.sh"

echo ""
if [ "$TARGET_MODE" = "local" ]; then
    echo "Done. Six components installed to $CLAUDE_DIR/ (project-local)."
else
    echo "Done. Six components installed to $CLAUDE_DIR/ (global)."
fi
echo ""
echo "=== Optional: PostToolUse hook ==="
echo ""
echo "To auto-run adversary-check.sh after every Write/Edit, add this to your"
if [ "$TARGET_MODE" = "local" ]; then
    echo "$CLAUDE_DIR/settings.json (merge with existing hooks if any):"
else
    echo "~/.claude/settings.json (merge with existing hooks if any):"
fi
echo ""
echo '  "hooks": {'
echo '    "PostToolUse": ['
echo '      {'
echo '        "matcher": "Write|Edit",'
echo '        "hooks": ['
echo '          {'
echo '            "type": "command",'
echo "            \"command\": \"bash $HOOK_PATH_DISPLAY . 2>/dev/null || true\""
echo '          }'
echo '        ]'
echo '      }'
echo '    ]'
echo '  }'
echo ""
