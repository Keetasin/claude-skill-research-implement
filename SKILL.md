---
name: research-implement
description: Research-plan-review-build-verify workflow with model split. Opus subagent researches and plans a minimal-change, research-grade best-practice solution, an Opus reviewer hardens the plan, Sonnet subagents implement it test-first, then verify with evidence and write a report with lessons. Run only when the user invokes /research-implement.
argument-hint: <task description>
disable-model-invocation: true
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "python3 ~/.claude/skills/research-implement/scripts/check_edit.py"
---

# research-implement

Task: $ARGUMENTS

Goal: highest-quality, research-grade, production-ready result with the **smallest necessary code change**.

Orchestrator = the main session. It does not do the heavy research or coding itself. It dispatches subagents, runs the deterministic scripts, asks the user, and keeps the docs. A skill cannot switch model mid-run, so each phase runs in a subagent with an explicit `model`.

`SKILL_DIR` = `~/.claude/skills/research-implement`. Role instructions live in `SKILL_DIR/reference/`. When spawning a subagent, tell it to read `reference/contract.md` and its role file, and give it only the inputs listed there. Do not paste the role file into the prompt.

| Role | Model | File |
|---|---|---|
| Code mapper | sonnet, `general-purpose` (not `Explore`: it cannot write files) | `reference/codemap.md` |
| Researcher | opus | `reference/research.md` |
| Planner | opus | `reference/planner.md` |
| Plan reviewer | opus | `reference/plan-reviewer.md` |
| Implementer | sonnet (opus on escalation) | `reference/implementer.md` |
| Change reviewer | opus | `reference/verifier.md` |

## Language and tokens

- First action: invoke the `caveman` skill with args `ultra`. It applies only to chat; docs, memory, code and comments stay normal prose. Last action: invoke `caveman` with args `off`.
- Talk to the user (chat and `AskUserQuestion`) in the user's language. Docs and subagent prompts may be English. Keep code, identifiers and error strings verbatim.
- Subagents reply with the short block from `contract.md`. Open their files only when a detail is needed.
- **Opus budget**: count Opus agents in `Status`. Before the 7th Opus agent for one task, stop and ask the user whether to continue.

## Setup

1. `slug` = kebab-case, ≤5 words. Task dir `TD` = `docs/tasks/<YYYY-MM-DD>-<slug>/`.
2. **Resume**: glob `docs/tasks/*-<slug>/` (any date) and any task dir whose `PLAN.md` goal matches. If one has an incomplete `Status`, resume at the first unchecked step. If several match, ask the user.
3. Read the project's `CLAUDE.md`, `MEMORY.md` index and prior task docs on the same area. Collect relevant lessons for every subagent.
4. `git status --short`: record whether the working tree is clean.
5. Step 0 triage, then baseline:
   - Find the test/lint commands (CLAUDE.md, pyproject, Makefile, CI config).
   - Normal/Large: run the full test and lint commands. Small: only tests and lint for the files to change. Spike: skip.
   - Record in `PLAN.md` the exact commands, exit codes and the tests that already fail. Only new failures count as regressions later.

`PLAN.md` starts with:

```
## Status
- [ ] 0 triage  - [ ] 1 plan  - [ ] 2 review  - [ ] 3 saved  - [ ] 4 implement  - [ ] 5 verify  - [ ] 6 report
Plan review round: 0/3   Fix loop: 0/3   Opus agents: 0/6
```

## Step 0 — Triage (orchestrator)

- **Spike**: the question is "can this work?" (library, API, approach feasibility). Run one Sonnet agent in the scratchpad, keep no code in the repo, write the finding to `REPORT.md`, then stop and ask the user.
- **Small**: the diff can be described in one sentence and touches ≤2 files, with no design choice and no research. Skip Steps 1–3. Write a short `PLAN.md` and `acceptance.json`, then Step 4 with one Sonnet agent. Step 5 reviewer optional; tests and the evidence gate still apply.
- **Normal**: one module or feature, needs design or research. All steps, one researcher.
- **Large**: several modules, architectural change or several open research questions. All steps, up to 2 researchers on separate questions.

If unsure, ask the user (`AskUserQuestion`). Record class and reason in `PLAN.md`.

## Step 1 — Research and plan

**1a. Fact-finding, in parallel (one message):** code mapper in mode MAP (writes `TD/CODEMAP.md`) and researcher(s) with the triage class and question list (write `TD/RESEARCH.md`).

**1b. Plan:** planner with task, class, constraints, baseline, lessons, `CODEMAP.md`, `RESEARCH.md`. It writes `PLAN.md` and `acceptance.json`.

If RESULT is `questions`: ask the user with `AskUserQuestion` (max 4 per call, recommended first, include "why it matters" in the description). Max 5 questions per task. SendMessage the answers to the same planner, which records them as `Q: … → A: …` under Decisions.

## Step 2 — Review the plan (max 3 rounds)

Fresh plan reviewer each round, with the review log. On `REVISE`, SendMessage the planner to fix blocking and major findings and fill the review log. Stop on `PASS` or after round 3; if still `REVISE`, show the open findings and ask the user.

## Step 3 — Save the plan

`TD` holds the final `PLAN.md`, `acceptance.json`, `CODEMAP.md`, `RESEARCH.md`, reviews. Show the user a short summary and the path.

## Step 4 — Implement

1. **Snapshot** (once, before the first implementer): `SKILL_DIR/scripts/snapshot.sh TD <every file in the change list>`. It saves the "before" state including uncommitted and untracked work. It refuses to run twice, so fix loops keep the original rollback point.
2. Spawn one implementer per file group, all in one message. Give each its group, interfaces, criteria, and the relevant `PLAN.md`/`CODEMAP.md` sections.
3. **Where agents edit**:
   - Dirty working tree: edit in place, no worktree. A worktree starts from HEAD and would not see uncommitted work; copying its files back would overwrite that work. Disjoint ownership prevents collisions.
   - Clean tree and 2+ parallel agents: `isolation: "worktree"`; each agent commits on its branch; the orchestrator merges (`git merge --no-ff`) or cherry-picks. A merge conflict means the work split was wrong: stop, resolve, record the lesson.
4. **Handle RESULT**:
   - `DONE`: go on.
   - `DONE_WITH_CONCERNS`: read the concerns; fix the plan or pass them to the Step 5 reviewer.
   - `NEEDS_CONTEXT`: supply the fact from `CODEMAP.md`/`PLAN.md` (or a code mapper) and re-dispatch the same agent with SendMessage.
   - `BLOCKED`: plan wrong → planner fixes the plan; task too hard → re-dispatch the group to an Opus implementer (counts toward the Opus budget).
5. **Rollback**: restore a file from `TD/snapshot/`, or delete it if listed in `snapshot/NEW_FILES`. Never `git checkout`/`git restore` on a dirty tree; that destroys the user's uncommitted work.

## Step 5 — Verify

1. Run the targeted tests from `acceptance.json`, then the baseline commands. Compare with the baseline.
2. `SKILL_DIR/scripts/make_diff.sh TD` → `TD/change.diff` plus `OUT_OF_PLAN` files (status changed but not in the plan). It cannot see a file that was already modified before the snapshot and modified again outside the plan; the reviewer covers that.
3. Change reviewer with the diff, summary, test results, review log. Needs `SPEC=PASS` and `QUALITY=PASS`.
4. UI/view/template changes: run the real app (`/run` skill) and check the flow.
5. **Fix loop** (max 3): new failures, blocking or major findings go back to Step 4 with finding ids and failing lines. If the **same** finding survives 2 fixes, do not try a third patch: send it to the planner for a root-cause rethink, update the plan, then implement. After 3 loops, stop and ask the user.

## Evidence gate (before Step 6)

Agent reports are claims, not evidence. The orchestrator itself re-runs every test command in `acceptance.json` and the baseline commands, then:

- Sets `passes` and `evidence` (command, exit code, pass/fail counts) per criterion in `acceptance.json`.
- Copies the commands, exit codes and counts into `REPORT.md`.
- Proceeds only if every criterion passes and there are no new failures vs baseline. Otherwise back to Step 5.

## Step 6 — Report and lessons

`REPORT.md` in `TD`:

- What was done, mapped to criteria ids.
- Evidence: commands, exit codes, counts, comparison with baseline.
- Errors found and fixed: **root cause** and a **rule to avoid repeating it**.
- Deviations from the plan and why.
- Remaining work: minor findings, open risks, better approaches or newer sources found.
- Cost: Opus and Sonnet agents, review rounds, fix loops.

Then:

- Code mapper in mode UPDATE: refresh `TD/CODEMAP.md` and merge into `docs/CODEMAP.md`.
- Save each reusable "do not repeat" lesson as a `feedback` memory (update an existing one instead of duplicating; add the `MEMORY.md` index line).
- Keep `TD/snapshot/` until the user accepts the change; it is the rollback point. Suggest adding `docs/tasks/*/snapshot/` to `.gitignore`.
- Tick all `Status` boxes. Do not commit unless the user asks.
- Final reply: 3–6 lines, status plus paths to `PLAN.md` and `REPORT.md`. Then `caveman off`.

## Rules

- Minimal change beats clever change: every added line costs review time and risk, so it needs a reason in the plan.
- A researched claim needs a verified source in `RESEARCH.md`, because unverified claims become wrong code that looks authoritative.
- Ask the user (with options) when the answer changes the design. Do not ask what the code or a sensible default answers.
- Roles stay separate: Sonnet maps and writes code, Opus researches, plans and reviews, the orchestrator coordinates, runs scripts and talks to the user.
