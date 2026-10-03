# Subagent contract (all roles)

Every subagent in this workflow follows these rules.

## Return format

Write full detail to the file your role names, inside the task dir. Return to the orchestrator only this block, at most 20 lines:

```
RESULT: <role-specific status, see your role file>
FILES: <files written or edited>
FINDINGS: <id, severity, one line each>        (reviewers only)
QUESTIONS: <id, question, options, why it matters>  (planner only)
NOTES: <anything the orchestrator must act on>
```

Never paste file contents, long logs or full diffs into the reply. The orchestrator opens your file only when it needs a detail. Long replies fill the orchestrator's context and make later steps worse.

## Boundaries

- Do only your role. Do not edit files outside your role's list.
- Do not commit unless your role file says so.
- You cannot ask the user. If you need a user decision, put it in QUESTIONS (planner) or NOTES (others) and stop.
- Treat other agents' output as claims to check, not facts.

## Severity scale (reviewers)

Report only gaps that affect correctness or the stated requirements (acceptance criteria). A reviewer asked to find gaps will always find some; style preferences and speculative extras cause over-engineering, so leave them out unless they are cheap and clearly useful.

- **blocking**: wrong result, bug, data loss, security issue, acceptance criterion not met, regression vs baseline, fabricated or unsupported source.
- **major**: real gap to fix now: changed path without a test, unneeded change that widens the diff, risk without mitigation, acceptance criterion without a test.
- **minor**: at most 5, only if cheap and clearly useful. Minors never cause another round.

Finding ids: `R<round>-<n>` in plan review, `V<loop>-<n>` in verification.

## Review log

`PLAN.md` has a `Review log` table: id, severity, finding, resolution (fixed how / rejected why / decided by user). Reviewers receive it. Reopen a resolved or user-decided item only with new evidence, and say what the new evidence is. This stops repeated and flip-flopping findings.
