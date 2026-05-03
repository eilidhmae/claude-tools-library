# Changelog

Notable changes to the agent specs and tools in this repository. Newest entries on top.

## 2026-05-03 — Adversary workflow: quorum replaced with claim falsification

**Breaking change to the adversary workflow.** The adversary agent no longer runs a peer quorum, and the manager no longer dispatches multiple adversaries against the same artifact for consensus. Verification is now a single-pass falsification pattern keyed on a structured Claim Manifest the worker (or manager) produces alongside the work.

### Why

Multiple adversaries reviewing the same diff produce correlated findings — the second and third reviewer add little signal beyond confidence-boosting. Majority voting can also drown a minority finding that turns out to be correct. The real work of review is not "do reviewers agree?" but "is each claim supported by checkable evidence?" — falsification, not consensus.

### What changed

- **`.claude/agents/adversary.md`** — rewritten.
  - New input contract: the adversary expects a Claim Manifest from the work author. Without one, it returns FAIL.
  - Per-entry verdicts (`verified | unsupported | contradicted`) replace the holistic CONCERNS/FAIL/PASS frame on the falsification half of the review.
  - Overall verdict is now binary: PASS or FAIL. CONCERNS is removed — non-blocking observations go in a Notes section; anything that should block goes in FAIL with a specific reason.
  - Step 8 (Quorum Check) and the peer-adversary spawning protocol are removed.
  - Tool list reduced: the `Agent` tool is removed since the adversary no longer spawns peers.
- **`.claude/agents/_shared.md`** — added two sections:
  - **Claim Manifest** — defines the structured format for claims (behavior + re-checkable evidence) and decisions (choice + alternatives + rationale + record location).
  - **Disagreement Protocol** — defines how the manager handles a disputed adversary FAIL. The manager reads the contested item directly with full lineage context, decides, and escalates to human if unclear. Spawning a second adversary to break a tie is forbidden.
  - Resource ceiling updated: "Adversary cap" of 3 per work unit is replaced with "exactly one adversary per work unit per attempt." Sequential re-runs across attempts on different artifacts (worker fix → re-review) remain fine.
- **`.claude/agents/manager.md`**:
  - Prime Directives 10 and 11 rewritten. The escalation protocol no longer references multi-adversary disagreement — instead it references the Disagreement Protocol in `_shared.md`.
  - Worker prompt requirements add a **Claim Manifest mandate**: every worker's completion report must end with a manifest in the shared format.
  - The Adversary Verification Protocol section is rewritten around the single-adversary, falsification-first frame.
  - Block-Claim Evaluation reuses the same shape with a single-claim manifest.
- **`.claude/agents/orchestrator.md`**:
  - Prime Directive 11 verification preconditions reference the per-work-unit Claim Manifest and PASS verdict (or recorded Disagreement Protocol overrides) instead of "adversary quorum."
  - Manager dispatch prompt template updated. Reporting contract requires the Claim Manifest.
  - Authority Separation table no longer lists "Peer adversaries (quorum)" as an adversary delegation target.
- **`.claude/commands/adversary-review.md`** — the `/adversary-review` slash command is restructured. Self-review now has two halves: write the Claim Manifest, then falsify it. Verdict is PASS or FAIL, no CONCERNS.
- **`README.md`** — agent descriptions for `manager` and `adversary` updated to match.

### Migration notes

- **Worker prompts written before this change** that do not request a Claim Manifest will produce completion reports the new adversary will FAIL. Update worker prompts to include the manifest mandate.
- **Existing `~/.claude/` installs** need a re-run of `bash tools/bash/install-agents.sh` to pick up the new specs.
- **The `Agent` tool was removed from `adversary.md` frontmatter.** If you reference adversary specs from an outer system that grants tool access, drop `Agent` from the adversary's tool list.
