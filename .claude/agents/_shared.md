# Shared Rules

Rules common to the `orchestrator`, `manager`, and `adversary` agents. Loaded via Prime Directive from each agent's own spec. If this file is missing, agents proceed with degraded context and report the absence in their completion report — they do not guess at the contents.

## Mechanical Baseline

Run the adversary-check script when assessing project state:

```bash
bash tools/bash/adversary-check.sh . || bash ~/.claude/hooks/adversary-check.sh .
```

The script **always exits 0**. Findings are in stdout — do not gate on exit code. Read the output and act on the flags it raises.

## Mutation Verification Safety

Applies to any agent running bash when verifying behaviour by mutating a file.

Banned commands during mutation revert (they operate on the whole working tree and will destroy uncommitted edits from other work in the session):

- `git checkout -- <file>`
- `git checkout <ref> -- <file>`
- `git restore <file>`
- `git reset --hard` (any form)
- `git stash` (any form)

Safe pattern: apply the mutation with the `Edit` tool, run the test to confirm the expected failure or pass, then call `Edit` again with the opposite change to revert. Agents without the `Edit` tool do not perform mutations; they report what must be demonstrated and the manager dispatches a worker to do the mutation test.

## Startup Reads

On every session start, in order:

1. Read `CLAUDE.md` in the project root. If it does not exist, follow the agent's own spec for creating or proceeding without it.
2. Read every document `CLAUDE.md` references, recursively.
3. Read `CHANGELOG.md` and `TODO.md` if they exist.
4. Run `git log --oneline -20` and `git status`.
5. Run the Mechanical Baseline.

Before accepting any goal, hold a clear internal picture of project architecture, current state, recent commits, pending work, and any flags from the Mechanical Baseline. Do not proceed until this picture is complete.

## Enqueue-Before-Ack

Persist next-actions before closing the current one. Specifically: update `TODO.md` with follow-up tasks and append to `CHANGELOG.md` *before* marking work as done or committing.

Rationale (Grail §7.3): if an agent closes a task and then fails before recording the follow-up, the follow-up is lost silently. Ordering the writes the other way — persist next, then close current — ensures that a crash between the two steps leaves the current task re-runnable rather than losing branches of work.

## Lineage-Scoped Writes

When a manager's dispatch prompt contains a `LINEAGE_ID` (set by an orchestrator), the manager's writes to project-level documents are **scoped to that lineage's draft directory**:

- `CLAUDE.md` updates → `.claude/drafts/<LINEAGE_ID>/CLAUDE-patch.md`
- `CHANGELOG.md` entries → `.claude/drafts/<LINEAGE_ID>/CHANGELOG-entries.md`
- `TODO.md` updates → `.claude/drafts/<LINEAGE_ID>/TODO-updates.md`

The orchestrator merges drafts into canonical `CLAUDE.md`, `CHANGELOG.md`, `TODO.md` at reconciliation, then deletes the drafts directory.

When no `LINEAGE_ID` is present (standalone manager, no orchestrator in the session), the manager writes directly to the canonical files. This is the single-writer case and cannot race.

File shapes for deterministic merge:

- `CHANGELOG-entries.md` — each entry preceded by `## <ISO-8601 completion timestamp>` for ordering. The **completion timestamp** is wall-clock time (`date -u +%Y-%m-%dT%H:%M:%SZ`) captured at the moment the manager appends the entry to this draft file, after the work unit's adversary quorum has passed. Not the worker's finish time, not the adversary's verdict time — the draft-write time. This makes merge order deterministic regardless of which parallel manager completes first.
- `TODO-updates.md` — two sections, `### Move to Done` and `### Add to Active`, one bullet per item.
- `CLAUDE-patch.md` — free-form prose describing the proposed change; the orchestrator applies with judgment or dispatches a reconciliation manager if lineages conflict.

## Payload-by-Reference

When briefing a worker, adversary, or manager, cite file paths, line numbers, and commit SHAs. Do not paste file contents inline unless the snippet is short and the reader would otherwise need to read an outsized file for a single line of context.

Rationale (Grail §8): inline state grows with task count and burns context proportionally. A path reference is O(1) in prompt size regardless of project size. The callee reads what it needs.

## Known Limitations and Resource Ceilings

These are operational bounds this system does not structurally enforce. Agents and humans should be aware.

- **Re-dispatch cap (orchestrator).** For any single goal, the orchestrator re-dispatches the same manager at most 2 times (initial + 2 retries = 3 attempts total). Hitting the cap triggers escalation to human.
- **Adversary cap (manager).** Manager-spawned adversaries for a single work unit are capped at 3. The adversary's own internal peer quorum is independent and capped at 3 total reviewers (self + 2 peers).
- **Worker fanout (manager).** At most 6 parallel workers per dispatch wave. If decomposition requires more, serialize waves.
- **Back-pressure.** No token-budget enforcement beyond the caps above. Runaway loops are bounded by the caps but can still be costly; human review catches what the caps miss.
- **Observability.** No persistent event log across sessions beyond `CHANGELOG.md` and git history. Mid-session reasoning is lost at session end.
- **`CLAUDE.md` freshness during parallel dispatch.** Under lineage-scoped drafts, canonical `CLAUDE.md` is not written mid-session by parallel managers — so within a single dispatch the manager sees a stable file. Cross-session staleness is handled by the Startup Reads.
