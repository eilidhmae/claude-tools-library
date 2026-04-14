# claude-tools-library

A collection of utility tools for use with Claude Code.

## Tools

### Go

#### [randstring](tools/golang/randstring/)

Cryptographically secure random alphanumeric string generator.

```bash
cd tools/golang/randstring
go build -o randstring

./randstring      # 32 characters (default)
./randstring 64   # 64 characters
```

### Python

#### [pdftotext](tools/python/pdftotext/)

Extract text from PDF files with page range support.

```bash
cd tools/python/pdftotext
pip install pypdf

python pdftotext.py document.pdf                    # Extract all pages
python pdftotext.py document.pdf -o output.txt      # Custom output file
python pdftotext.py document.pdf -s 1 -e 10         # Pages 1-10 only
python pdftotext.py document.pdf --no-page-numbers  # Skip page markers
```

### Bash

#### [adversary-check](tools/bash/adversary-check.sh)

Mechanical verification of recent code changes. Fast, no LLM needed.

```bash
tools/bash/adversary-check.sh                    # Check working tree changes
tools/bash/adversary-check.sh .                   # Explicit project root
tools/bash/adversary-check.sh . HEAD~3..HEAD      # Check specific commit range
```

Checks: large file additions, missing test files, new TODOs/FIXMEs, commented-out code, and runs detected test suites.

## Agents

### [adversary](.claude/agents/adversary.md)

Adversarial code reviewer that independently verifies claims, challenges complexity, and provides a skeptical second opinion. Runs as a read-only subagent with its own context window. On a CONCERNS/FAIL verdict it spawns a peer adversary for quorum (up to three reviewers total, majority wins).

**Invocation paths:**

| Method | When to use |
|--------|-------------|
| Subagent spawn | After completing a feature, before PR -- highest independence |
| `/adversary-review` command | Quick self-check, same context -- fast but less independent |
| PostToolUse hook (automatic) | Runs `adversary-check.sh` after every Write/Edit |
| `adversary-check.sh` standalone | CI, pre-commit, manual verification |

**Install globally** (available in all projects):

```bash
# Run the install script from the repo root
bash tools/bash/install-adversary.sh
```

Or install manually -- see [install-adversary.sh](tools/bash/install-adversary.sh) for details.

**Components installed:**

| Component | Global path | Purpose |
|-----------|-------------|---------|
| Subagent | `~/.claude/agents/adversary.md` | Full adversarial reviewer (independent context) |
| Slash command | `~/.claude/commands/adversary-review.md` | `/adversary-review` self-check |
| Verification script | `~/.claude/hooks/adversary-check.sh` | Mechanical checks (no LLM) |

The install script also shows how to add the optional PostToolUse hook to your global `~/.claude/settings.json`.

## Commands

### [/adversary-review](.claude/commands/adversary-review.md)

Self-review checklist for the primary agent to adversarially audit its own work. Lighter-weight than spawning the full adversary subagent. Invoke with `/adversary-review`.

## Skills

### [tmux-agents](skills/TMUX_AGENTS.md)

Multi-agent tmux workflow for parallel sub-agent work.

## Structure

```
.claude/
├── agents/
│   └── adversary.md       # Adversarial reviewer subagent
├── commands/
│   └── adversary-review.md # Self-review slash command
├── settings.json          # Status line + PostToolUse hooks
└── statusline-command.sh  # Context window status display
skills/
└── TMUX_AGENTS.md         # Tmux multi-agent workflow
tools/
├── bash/
│   ├── adversary-check.sh    # Mechanical verification script
│   ├── install-adversary.sh  # Global installer
│   └── statusline-command.sh
├── golang/
│   └── randstring/        # Random string generator
└── python/
    └── pdftotext/         # PDF text extraction
```

## Contributing

Add new tools under `tools/<language>/<tool-name>/` with their own README.
