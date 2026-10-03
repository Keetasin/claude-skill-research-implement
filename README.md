# research-implement

A [Claude Code](https://code.claude.com) skill that runs a **research → plan → review → implement → verify** workflow with a model split: Opus researches, plans and reviews; Sonnet maps code and writes code. It aims for the **smallest necessary diff** with best practice backed by verifiable sources.

[ภาษาไทย](README.th.md)

## Why

One long prompt tends to mix design, coding and checking in one context. This skill splits the work into roles with clear files and hand-offs, so:

- Opus tokens go to research, design and review, not to reading the repo or typing code.
- Every plan is reviewed before code is written, and every change is reviewed against the plan.
- "Done" means the orchestrator re-ran the tests itself, not that an agent said so.
- Lessons are saved, so the same mistake is not repeated.

## Requirements

- Claude Code with access to Opus and Sonnet subagents (the `Agent` tool with a `model` parameter).
- `bash`, `git`, `python3`, `sha256sum`, `diff` (standard on Linux and macOS; on macOS install coreutils or replace `sha256sum` with `shasum -a 256`).
- A git repository for the project you run it in.

## Install

```bash
git clone https://github.com/Keetasin/claude-skill-research-implement.git \
  ~/.claude/skills/research-implement
```

Or, from a clone elsewhere: `./install.sh` (copies the skill into `~/.claude/skills/research-implement`, or into `./.claude/skills/research-implement` with `--project`).

Restart Claude Code, then run `/research-implement <task>`.

## Use

```
/research-implement add rate limiting to the login view
```

The skill runs only when you type the command (`disable-model-invocation: true`).

It will:

1. Classify the task: **Spike**, **Small**, **Normal** or **Large**.
2. Ask you short multiple-choice questions when an answer changes the design (max 5).
3. Write everything to `docs/tasks/<date>-<slug>/` in your project.
4. Stop and ask you if a loop limit is reached.

It never commits. It saves reusable "do not repeat" lessons as Claude Code memory files.

## How it works

| Step | Who | Output |
|---|---|---|
| 0 Triage | orchestrator | class: Spike / Small / Normal / Large |
| 1a Fact-finding (parallel) | Sonnet code mapper, Opus researcher | `CODEMAP.md`, `RESEARCH.md` |
| 1b Plan | Opus planner | `PLAN.md`, `acceptance.json` |
| 2 Plan review (max 3 rounds) | fresh Opus reviewer each round | `review-N.md`, verdict PASS / REVISE |
| 3 Save plan | orchestrator | final plan files |
| 4 Implement | Sonnet implementers, one per file group, test first | code, `impl-<group>.md` |
| 5 Verify (max 3 fix loops) | orchestrator runs tests, Opus change reviewer | `change.diff`, `verify-N.md` (SPEC and QUALITY verdicts) |
| Evidence gate | orchestrator re-runs all tests | `acceptance.json` `passes` + `evidence` |
| 6 Report | orchestrator, Sonnet code mapper | `REPORT.md`, project `docs/CODEMAP.md`, memory lessons |

Design points:

- **Minimal diff.** The planner must justify every changed file and compares at least two approaches.
- **Acceptance IDs.** `acceptance.json` lists AC-1… each with a test command and a file group. The plan reviewer checks coverage both ways.
- **Test first.** Implementers write the new test, watch it fail, then fix.
- **Snapshot, not git, for rollback.** `scripts/snapshot.sh` copies the files before the change, including uncommitted work, so a dirty working tree is safe. Agents edit in place on a dirty tree, and in worktrees only when the tree is clean.
- **Severity scale.** Findings are blocking, major or minor. Only blocking and major cause another round.
- **Project code map.** `docs/CODEMAP.md` stores per-area maps with file hashes, so the next task skips re-reading unchanged code.
- **Short subagent replies.** Agents write details to files and reply with at most 20 lines, which keeps the orchestrator's context small.
- **Opus budget.** The skill stops and asks before spawning the 7th Opus agent for one task.

## Files

```
SKILL.md              orchestration (loaded when the skill runs)
reference/            one instruction file per role, read by each subagent
scripts/              snapshot.sh, make_diff.sh, codemap_hash.sh, check_edit.py
evals/                make_fixture.sh and cases.md (3 test cases)
install.sh            copy helper
```

## Test it

```bash
evals/make_fixture.sh /tmp/ri-eval-1
cd /tmp/ri-eval-1 && claude
/research-implement fix bulk_price: discount should start at exactly 10 items
```

Score the result against `evals/cases.md`.

## Known limitations

- The `PostToolUse` hook in `SKILL.md` frontmatter syntax-checks edited `.py` files. Whether skill-scoped hooks fire for subagent tool calls is not documented; `evals/cases.md` case 3 checks it. If it does not fire, move the hook to `settings.json`. Tests in Step 5 still catch errors either way.
- `make_diff.sh` cannot detect an out-of-plan edit to a file that already had uncommitted changes before the snapshot. The change reviewer covers that case.
- Cost: a Normal task uses several Opus agents. Triage sends small tasks through a short path.
- The syntax hook and the examples assume Python projects; other languages work, but without the hook guard.

## License

MIT, see [LICENSE](LICENSE).
