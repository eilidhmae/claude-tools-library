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

Three coordinating agents that share a common rule set and can be composed into a single-session hierarchy (orchestrator → managers → workers/adversaries/research subagents) or used independently. The design borrows selectively from the [Grail whitepaper](https://github.com/RobeyLabs/Grail) — goal regression framing, lineage-scoped state, enqueue-before-ack, bounded recursion — while explicitly owning the deviation to a centralized dispatcher model. See [`.claude/agents/_shared.md`](.claude/agents/_shared.md) for the rules every agent follows.

### [orchestrator](.claude/agents/orchestrator.md)

Top-level coordinator. Reconciles lineage-scoped drafts produced by parallel managers into canonical `CLAUDE.md` / `CHANGELOG.md` / `TODO.md`, owns the commit process, and dispatches manager subagents with `LINEAGE_ID`s. Activates on session start, Conflict (managers don't compose), Stall (no progress), or Ambiguity (criteria pass but directive unmet). Does not spawn workers or adversaries directly.

### [manager](.claude/agents/manager.md)

Per-lineage coordinator. Decomposes a goal into worker-sized tasks, dispatches workers with TDD, runs adversary quorum to verify completion, and evaluates block claims through adversaries (block-claim evaluation scope) rather than re-dispatching workers. Runs in two modes detected by `LINEAGE_ID` in its dispatch prompt — standalone (writes canonical project docs and commits) or orchestrated (writes lineage-scoped drafts for the orchestrator to merge).

### [adversary](.claude/agents/adversary.md)

Adversarial code reviewer and block-claim evaluator. Read-only subagent with its own context window. On a CONCERNS/FAIL verdict it spawns a peer adversary for quorum (up to three reviewers total, majority wins). Supports two review scopes: code-change review (full protocol) and block-claim evaluation (focused on whether a worker's reported prerequisite is real).

**Invocation paths:**

| Method | When to use |
|--------|-------------|
| Subagent spawn | After completing a feature, before PR -- highest independence |
| `/adversary-review` command | Quick self-check, same context -- fast but less independent |
| PostToolUse hook (automatic) | Runs `adversary-check.sh` after every Write/Edit |
| `adversary-check.sh` standalone | CI, pre-commit, manual verification |

### Install

Global (available in all projects):

```bash
bash tools/bash/install-agents.sh
```

Project-local (into `./.claude/` of the current repo; requires a git working tree):

```bash
bash tools/bash/install-agents.sh --local
```

Add `--force` (or `-y`) to skip the overwrite prompt when re-installing non-interactively. See [install-agents.sh](tools/bash/install-agents.sh) for details.

**Components installed:**

| Component | Path (global) | Purpose |
|-----------|-------------|---------|
| Orchestrator spec | `~/.claude/agents/orchestrator.md` | Top-level coordinator |
| Manager spec | `~/.claude/agents/manager.md` | Per-lineage coordinator |
| Adversary spec | `~/.claude/agents/adversary.md` | Independent reviewer |
| Shared rules | `~/.claude/agents/_shared.md` | Rules common to all three agents |
| Slash command | `~/.claude/commands/adversary-review.md` | `/adversary-review` self-check |
| Verification script | `~/.claude/hooks/adversary-check.sh` | Mechanical checks (no LLM) |

Project-local install writes the same six files under `./.claude/` instead. The install script also prints the optional PostToolUse hook snippet to add to `~/.claude/settings.json` (or the project-local equivalent).

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
│   ├── _shared.md          # Rules shared by all three agents
│   ├── adversary.md        # Adversarial reviewer subagent
│   ├── manager.md          # Per-lineage coordinator
│   └── orchestrator.md     # Top-level coordinator
├── commands/
│   └── adversary-review.md # Self-review slash command
├── settings.json           # Status line + PostToolUse hooks
└── statusline-command.sh   # Context window status display
skills/
└── TMUX_AGENTS.md          # Tmux multi-agent workflow
tools/
├── bash/
│   ├── adversary-check.sh    # Mechanical verification script
│   ├── install-agents.sh     # Global and project-local installer
│   └── statusline-command.sh
├── golang/
│   └── randstring/         # Random string generator
└── python/
    └── pdftotext/          # PDF text extraction
```

## Contributing

Add new tools under `tools/<language>/<tool-name>/` with their own README.
