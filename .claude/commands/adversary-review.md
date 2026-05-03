# Adversarial Self-Review

Run this against your own recent work. Be honest — the point is to catch your own mistakes before someone else does.

This is a self-review, so it cannot give you the independent context an `adversary` subagent dispatch gives. Treat it as a pre-check: it catches obvious failures before you waste an adversary's time. It is not a substitute for the subagent on non-trivial work.

## When to Use

- Before reporting a task as done
- Before committing code
- After completing an implementation task
- When the user says "check your work" or "review this"

## Workflow

The review has two halves: build a Claim Manifest, then falsify it.

### Half 1: Build the Claim Manifest

Stop and write down, in the format below, what you assert is true about the work you did. Do not skip this step. If you cannot articulate the claims, you do not understand what you delivered.

```
## Claim Manifest

### Claims (what the work asserts about behavior)
- C1: <statement>
  Evidence: <test file:line + command, or code file:line, or short captured output>
- C2: ...

### Decisions (non-obvious design choices)
- D1: <choice>
  Alternatives: <at least one rejected option>
  Rationale: <concrete reason — not "it seemed cleaner">
  Recorded: <where this is written down>
```

One claim per behavior the work is responsible for. One decision per non-obvious design choice. A bug fix may have a single C1; a refactor with no behavior change has a D1 ("no behavior change") with the diff itself as evidence.

If you find yourself unable to cite a re-checkable evidence pointer for a claim, the claim is not ready — either add the test, point to the explicit code, or remove the claim.

### Half 2: Falsify the Manifest

Now switch hats. You wrote the manifest; now try to break it.

#### 1. Mechanical baseline

Run the Mechanical Baseline from `.claude/agents/_shared.md` (or `~/.claude/agents/_shared.md`). If unavailable, fall back to:

```bash
git diff --stat HEAD
git status
```

#### 2. Per-claim falsification

For each `C` entry: re-run the cited test or re-read the cited code. Mark `verified | unsupported | contradicted`. Be strict — `verified` means you tried to falsify and could not, not "it sounds right."

For each `D` entry: confirm the alternatives and rationale are recorded where the manifest points. You are not judging whether the decision was right; you are checking it was deliberate and recorded.

If any entry is `unsupported` or `contradicted`, fix the work or fix the manifest before continuing. Do not paper over it.

#### 3. Independent scan

Look for problems the manifest does not claim — these are the things you might have missed by being too close to the work.

- **Scope creep.** Files changed that weren't part of the request? Features added beyond what was asked? "Improvements" to surrounding code? Comments or annotations on unchanged code?
- **Complexity.** Could this be done with fewer files, fewer lines, fewer abstractions? Functions over 30 lines, files over 150 lines, new dependencies, premature generalization, feature flags or backwards-compat shims that nobody asked for?
- **Hidden assumptions.** What does the code assume about the environment, input, external services, or user intent? Are any of those undocumented?
- **Security.** Unsanitized input in shell commands? Unsanitized paths in file ops? Hardcoded secrets? Unsafe defaults?
- **Alternative approach.** Describe at least one simpler alternative. If the manifest's `D` entries already cover this, only flag if you see an alternative they missed.

## Verdict

End with one of:

- **PASS** — every manifest entry verifies, and independent findings are minor or absent.
- **FAIL** — at least one manifest entry is unsupported or contradicted, OR an independent finding is severe enough to block (security issue, scope creep that changes meaning, missing test for material behavior).

There is no `CONCERNS` verdict. Independent findings that are real but not blocking go under "Notes." Anything that should block goes under FAIL with a specific reason.

Report your findings honestly. Do not bury them in qualifiers or optimistic language. Include the manifest in your report — it travels with the work.

## Escalation

Self-review is biased — you are grading your own work. If your verdict is **PASS** on a non-trivial change, consider invoking the `adversary` subagent (`Agent` tool, `subagent_type: adversary`) for independent falsification before declaring the task done. Hand it the same manifest you just built. The subagent runs in its own context and will return a per-claim verdict you cannot get from self-review.
