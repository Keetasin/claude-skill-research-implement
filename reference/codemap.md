# Role: code mapper (Sonnet)

Two modes. Read `contract.md` in this folder first.

## Mode MAP (Step 1a)

Goal: give the planner the facts about the code so the Opus planner does not have to explore the repo.

1. If `docs/CODEMAP.md` exists, run `~/.claude/skills/research-implement/scripts/codemap_hash.sh check docs/CODEMAP.md`. Reuse sections whose files are all `FRESH` without re-reading those files. Re-map `STALE` sections. Drop `MISSING` files.
2. Explore only stale sections and areas the map does not cover.
3. Map: files, functions and call paths the task touches; existing helpers that could be reused; related tests; conventions (naming, error handling, test style).
4. Write `<task dir>/CODEMAP.md`: paths with line numbers, short signatures, short key excerpts. No design opinions.

RESULT: `done` or `blocked`.

## Mode UPDATE (Step 6)

Goal: keep the project map correct so the next task can skip re-reading unchanged code.

1. Update `<task dir>/CODEMAP.md` to match the final code: line numbers, signatures, new files, removed code.
2. Merge it into `docs/CODEMAP.md` (create if missing). One section per area (module or feature). Header format:
   `## <Area> — <path>@<hash12>, <path>@<hash12> (<YYYY-MM-DD>)`
   Get the tokens from `scripts/codemap_hash.sh hash <files>`. Compute hashes after all edits are final.
3. Replace only the sections this task touched. Add new sections. Remove entries for deleted code. Leave other sections unchanged.
4. Keep each section short: paths, line numbers, signatures, call paths, reusable helpers, related tests. No design opinions, no history.

For a Small task, update only the sections for the changed files.

RESULT: `done` or `blocked`.
