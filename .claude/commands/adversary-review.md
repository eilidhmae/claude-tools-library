# Adversarial Self-Review

Run this checklist against your own recent work. Be honest -- the point is to catch your own mistakes before someone else does.

## When to Use

- Before committing code
- After completing an implementation task
- When the user says "check your work" or "review this"
- When you're about to report a task as done

## Checklist

### 1. Did the changes actually happen?

```bash
git diff --stat HEAD
git status
```

- Compare the output against what you told the user you did
- Every file you mentioned should appear in the diff
- No files you didn't mention should appear (scope creep)
- If you said you added a test, verify it exists and is meaningful

### 2. Do tests exist and pass?

Run the relevant test suite:
```bash
go test ./...        # Go
pytest               # Python
npm test             # Node
```

- If tests pass, are they testing real behavior or just asserting true?
- If no tests exist for your changes, flag it to the user
- If you added tests, do they cover edge cases or just the happy path?

### 3. Is the complexity justified?

For each file you changed, ask:
- Could this be done with fewer files?
- Could this be done with fewer lines?
- Did I add abstractions that serve no current use case?
- Did I add dependencies I could avoid?
- Are there functions over 30 lines that could be simpler?
- Are there files over 150 lines that could be split?
- Did I add feature flags, backwards-compat shims, or config options that nobody asked for?

### 4. Did I stay in scope?

Compare your changes against the original request:
- Did I change files that weren't part of the request?
- Did I add features beyond what was asked?
- Did I "improve" surrounding code that wasn't broken?
- Did I add comments or docstrings to code I didn't change?

### 5. What assumptions did I make?

List them explicitly:
- About the runtime environment
- About input data format and validity
- About external service availability
- About what the user actually wanted

### 6. Is there a simpler way?

Describe at least one simpler alternative to your approach. Be honest about the tradeoff. If your approach is genuinely the simplest, say so and explain why.

### 7. Quick security scan

- Any unsanitized input in shell commands?
- Any unsanitized paths in file operations?
- Any secrets hardcoded?
- Any unsafe defaults?

## Report to User

After running this checklist, report your findings honestly. If you found issues, say so. Do not bury findings in qualifiers or optimistic language.

End with: **PASS**, **CONCERNS**, or **FAIL** and specific file:line references for any issues.
