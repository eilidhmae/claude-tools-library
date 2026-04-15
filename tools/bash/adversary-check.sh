#!/usr/bin/env bash
#
# adversary-check.sh -- Mechanical verification of recent code changes.
# Runs fast, no LLM needed. Reports red flags for human or agent review.
#
# Usage: adversary-check.sh [project-root] [commit-range]
#   project-root  Directory to check (default: current directory)
#   commit-range  Git range to diff (default: working tree changes)
#
# Always exits 0 -- this is informational, not a gate.

set -euo pipefail

PROJECT_ROOT="${1:-.}"
COMMIT_RANGE="${2:-}"

# Validate commit range: only allow git ref characters (alphanumeric, dots, tildes, carets, slashes, dashes)
if [ -n "$COMMIT_RANGE" ] && ! echo "$COMMIT_RANGE" | grep -qE '^[a-zA-Z0-9._/~^-]+(\.\.[a-zA-Z0-9._/~^-]+)?$'; then
    echo "ERROR: Invalid commit range format: $COMMIT_RANGE"
    exit 0
fi

cd "$PROJECT_ROOT"

# Ensure we're in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "WARNING: Not a git repository. Skipping git-based checks."
    exit 0
fi

# --- Determine diff source ---
if [ -n "$COMMIT_RANGE" ]; then
    DIFF_CMD="git diff $COMMIT_RANGE"
    DIFF_STAT_CMD="git diff --stat $COMMIT_RANGE"
    DIFF_LABEL="range: $COMMIT_RANGE"
else
    # Combine staged + unstaged working tree changes
    DIFF_CMD="git diff HEAD"
    DIFF_STAT_CMD="git diff --stat HEAD"
    DIFF_LABEL="working tree vs HEAD"

    # If HEAD doesn't exist (fresh repo), diff against empty tree
    if ! git rev-parse HEAD &>/dev/null; then
        EMPTY_TREE=$(git hash-object -t tree /dev/null)
        DIFF_CMD="git diff $EMPTY_TREE"
        DIFF_STAT_CMD="git diff --stat $EMPTY_TREE"
        DIFF_LABEL="all files (fresh repo)"
    fi
fi

echo "========================================="
echo " ADVERSARY CHECK REPORT"
echo "========================================="
echo "Project: $(pwd)"
echo "Diff:    $DIFF_LABEL"
echo "Time:    $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# --- Changed files summary ---
echo "--- FILES CHANGED ---"
STAT_OUTPUT=$($DIFF_STAT_CMD 2>/dev/null || echo "(no changes)")
echo "$STAT_OUTPUT"
echo ""

if [ -n "$COMMIT_RANGE" ]; then
    CHANGED_FILES=$(git diff --name-only "$COMMIT_RANGE" 2>/dev/null || true)
else
    CHANGED_FILES=$(
        { git diff --name-only HEAD 2>/dev/null
          git ls-files --others --exclude-standard 2>/dev/null
        } | sort -u
    )
fi
if [ -z "$CHANGED_FILES" ]; then
    echo "No changes detected."
    exit 0
fi

FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
echo "Total files changed: $FILE_COUNT"
echo ""

# --- Large additions ---
echo "--- LARGE FILES (>150 lines added) ---"
FOUND_LARGE=0
while IFS= read -r file; do
    [ -z "$file" ] && continue
    ADDED=$($DIFF_CMD -- "$file" 2>/dev/null | grep -c '^+[^+]' || true)
    if [ "$ADDED" -gt 150 ]; then
        echo "  WARNING: $file (+$ADDED lines)"
        FOUND_LARGE=1
    fi
done <<< "$CHANGED_FILES"
if [ "$FOUND_LARGE" -eq 0 ]; then
    echo "  (none)"
fi
echo ""

# --- Missing test files ---
echo "--- MISSING TEST FILES ---"
FOUND_MISSING=0
while IFS= read -r file; do
    [ -z "$file" ] && continue
    # Skip test files, configs, docs, and non-code files
    case "$file" in
        *_test.go|*_test.py|*.test.js|*.test.ts|*.spec.js|*.spec.ts) continue ;;
        *.md|*.txt|*.json|*.yaml|*.yml|*.toml|*.cfg|*.ini) continue ;;
        *.sh|Makefile|Dockerfile|*.lock|*.sum) continue ;;
    esac

    DIR=$(dirname "$file")
    BASE=$(basename "$file")
    EXT="${BASE##*.}"
    NAME="${BASE%.*}"

    case "$EXT" in
        go)  TEST_FILE="$DIR/${NAME}_test.go" ;;
        py)  TEST_FILE="$DIR/test_${NAME}.py"
             [ -f "$TEST_FILE" ] || TEST_FILE="$DIR/${NAME}_test.py" ;;
        js)  TEST_FILE="$DIR/${NAME}.test.js" ;;
        ts)  TEST_FILE="$DIR/${NAME}.test.ts" ;;
        tsx) TEST_FILE="$DIR/${NAME}.test.tsx" ;;
        jsx) TEST_FILE="$DIR/${NAME}.test.jsx" ;;
        *)   continue ;;
    esac

    if [ ! -f "$TEST_FILE" ]; then
        echo "  MISSING: $file has no test file (expected: $TEST_FILE)"
        FOUND_MISSING=1
    fi
done <<< "$CHANGED_FILES"
if [ "$FOUND_MISSING" -eq 0 ]; then
    echo "  (all changed source files have test files)"
fi
echo ""

# --- TODOs and FIXMEs in new code ---
echo "--- NEW TODOs/FIXMEs ---"
TODO_LINES=$($DIFF_CMD 2>/dev/null | grep -n '^+' | grep -iE 'TODO|FIXME|HACK|XXX' | head -20 || true)
if [ -n "$TODO_LINES" ]; then
    echo "$TODO_LINES" | while IFS= read -r line; do
        echo "  $line"
    done
else
    echo "  (none)"
fi
echo ""

# --- Commented-out code ---
echo "--- COMMENTED-OUT CODE (in additions) ---"
# Heuristic: lines starting with + that contain common comment-then-code patterns
COMMENTED=$($DIFF_CMD 2>/dev/null | grep '^+' | grep -E '^\+\s*(//|#)\s*(if |for |func |def |class |return |import |var |let |const )' | head -10 || true)
if [ -n "$COMMENTED" ]; then
    echo "$COMMENTED" | while IFS= read -r line; do
        echo "  $line"
    done
else
    echo "  (none detected)"
fi
echo ""

# --- Merge conflict markers ---
echo "--- MERGE CONFLICT MARKERS ---"
MARKERS=$($DIFF_CMD 2>/dev/null | grep -E '^\+(<{7}|={7}|>{7})' | head -20 || true)
if [ -n "$MARKERS" ]; then
    echo "$MARKERS" | while IFS= read -r line; do
        echo "  $line"
    done
else
    echo "  (none)"
fi
echo ""

# --- Test execution ---
echo "--- TEST RESULTS ---"
RAN_TESTS=0

# Go tests
if echo "$CHANGED_FILES" | grep -q '\.go$'; then
    GO_MODS=$(find "$PROJECT_ROOT" -name go.mod -not -path '*/vendor/*' -not -path '*/node_modules/*' 2>/dev/null)
    if [ -z "$GO_MODS" ]; then
        echo "  (no go.mod found; skipping Go tests)"
    else
        while IFS= read -r modfile; do
            [ -z "$modfile" ] && continue
            moddir=$(dirname "$modfile")
            echo "  Running: go test ./... (in $moddir)"
            if GO_OUTPUT=$(cd "$moddir" && go test ./... 2>&1); then
                echo "  PASS: Go tests passed ($moddir)"
            else
                echo "  FAIL: Go tests failed ($moddir)"
                echo "$GO_OUTPUT" | tail -20 | sed 's/^/    /'
            fi
        done <<< "$GO_MODS"
    fi
    RAN_TESTS=1
fi

# Python tests
if echo "$CHANGED_FILES" | grep -q '\.py$'; then
    if command -v pytest &>/dev/null; then
        echo "  Running: pytest"
        if PY_OUTPUT=$(cd "$PROJECT_ROOT" && pytest --tb=short 2>&1); then
            echo "  PASS: Python tests passed"
        else
            echo "  FAIL: Python tests failed"
            echo "$PY_OUTPUT" | tail -20 | sed 's/^/    /'
        fi
        RAN_TESTS=1
    fi
fi

# Node tests
if echo "$CHANGED_FILES" | grep -qE '\.(js|ts|tsx|jsx)$'; then
    if [ -f "$PROJECT_ROOT/package.json" ]; then
        if grep -q '"test"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
            echo "  Running: npm test"
            if NODE_OUTPUT=$(cd "$PROJECT_ROOT" && npm test 2>&1); then
                echo "  PASS: Node tests passed"
            else
                echo "  FAIL: Node tests failed"
                echo "$NODE_OUTPUT" | tail -20 | sed 's/^/    /'
            fi
            RAN_TESTS=1
        fi
    fi
fi

if [ "$RAN_TESTS" -eq 0 ]; then
    echo "  (no test runner detected for changed files)"
fi
echo ""

echo "========================================="
echo " END ADVERSARY CHECK"
echo "========================================="

exit 0
