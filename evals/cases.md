# Evals for research-implement

Run each case in a fresh fixture, in a new Claude Code session started inside the fixture dir:

```
~/.claude/skills/research-implement/evals/make_fixture.sh /tmp/ri-eval-<n>
cd /tmp/ri-eval-<n> && claude
```

Score each check pass/fail. Re-run all three after any change to the skill. A useful comparison: run case 2 once without the skill (plain prompt) and compare diff size, tests and cost.

Fixture facts: dirty tree (uncommitted `item_count` in `shop/cart.py`), `test_money_negative_preexisting_failure` fails before any change.

## Case 1: Small

Prompt: `/research-implement fix bulk_price: discount should start at exactly 10 items`

- [ ] Triage = Small, with a one-sentence diff description. No researcher, planner or plan reviewer spawned (0 Opus agents).
- [ ] Baseline ran only the cart tests (or noted the pre-existing failure as out of scope).
- [ ] Implementer wrote a test for qty == 10 first and recorded it failing, then fixed `>` to `>=`.
- [ ] Uncommitted `item_count` still present after the task.
- [ ] `change.diff` shows only the `bulk_price` change and the new test, not `item_count`.
- [ ] Evidence gate: `REPORT.md` has the command, exit code and counts run by the orchestrator.

## Case 2: Normal

Prompt: `/research-implement add money rounding that is correct for currency (no float rounding errors) and use it in apply_discount`

- [ ] Triage = Normal. Code mapper (Sonnet, general-purpose) and researcher (Opus) ran in parallel, and `CODEMAP.md` exists.
- [ ] `RESEARCH.md` cites fetched sources (e.g. Python `decimal` docs) marked `verified`.
- [ ] Planner asked ≤5 questions through the orchestrator (e.g. rounding mode), each with options and why it matters.
- [ ] `acceptance.json` has ids, a test per criterion, and every file group maps to a criterion.
- [ ] Plan review ran; review log filled; no repeated finding across rounds.
- [ ] Change reviewer returned both SPEC and QUALITY verdicts.
- [ ] Diff is minimal: no unrelated refactor of `subtotal` or `text.py`.
- [ ] `docs/CODEMAP.md` created with `path@hash12` headers; `codemap_hash.sh check` reports FRESH for the touched files.
- [ ] `test_money_negative_preexisting_failure` still fails and is reported as pre-existing, not "fixed" or weakened.

## Case 3: Resume, rollback and hook

1. Start case 2. Interrupt the session after Step 3 (plan saved).
2. New session: same prompt.
   - [ ] Resumes at Step 4; does not spawn a new researcher or planner.
3. During Step 4, before the implementer runs, add to the prompt: "the implementer must first save a file with a syntax error, then fix it".
   - [ ] The PostToolUse hook error (`syntax error: ...`) appears in the implementer subagent's transcript. If not, skill-scoped hooks do not reach subagents: move the hook to `settings.json`.
4. Ask: "roll back the change".
   - [ ] Files restored from `snapshot/`, new files deleted, no `git checkout`/`git restore` used, uncommitted `item_count` intact.
