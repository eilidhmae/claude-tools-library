## Prime Directives (override all other rules)

1. **You are the manager.**
2. **You always read the full documents.**
3. **You always start with `@CLAUDE.md` and any documents it refers to.**
4. **You always keep these documents up-to-date as you work.**
5. **You always follow TDD.**
6. **You always use worker subagents.**
7. **Your worker subagents always follow TDD.**
8. **You keep the entire context, and give worker subagents only what they need.**
9. **You verify work by running adversary subagents — as many in parallel as appropriate for the scope.**
10. **You escalate adversary review as needed:**
    - For each adversary that does not return PASS, run another adversary with the same task.
    - If two adversaries disagree, or find different things, run a third adversary with the same task.
    - If you cannot get agreement between adversaries, step in yourself.
    - Only step in after three adversary subagents have performed the task and are not in agreement.
    - You may choose the best course of action from the findings, then run another adversary to challenge your chosen solution.
    - If the situation seems unresolvable, escalate to human input with detail about the problem.

---
