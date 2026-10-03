#!/usr/bin/env bash
# Build the change diff against the snapshot and flag files changed outside the plan.
# Usage: make_diff.sh <task_dir>   (run from the repo root)
# Writes <task_dir>/change.diff. Prints a summary and any OUT_OF_PLAN files.
set -euo pipefail

task_dir=${1:?usage: make_diff.sh <task_dir>}
snap="$task_dir/snapshot"
out="$task_dir/change.diff"
[ -d "$snap" ] || { echo "no snapshot at $snap; run snapshot.sh first" >&2; exit 1; }

: > "$out"
planned=$(mktemp)
trap 'rm -f "$planned"' EXIT

while IFS= read -r -d '' s; do
  f=${s#"$snap/"}
  case "$f" in NEW_FILES|GIT_STATUS_BEFORE) continue ;; esac
  echo "$f" >> "$planned"
  if [ -f "$f" ]; then
    diff -uN --label "a/$f" --label "b/$f" "$s" "$f" >> "$out" || true
  else
    diff -uN --label "a/$f" --label "b/$f" "$s" /dev/null >> "$out" || true
  fi
done < <(find "$snap" -type f -print0)

while IFS= read -r f; do
  [ -n "$f" ] || continue
  echo "$f" >> "$planned"
  [ -f "$f" ] && { diff -uN --label "a/$f" --label "b/$f" /dev/null "$f" >> "$out" || true; }
done < "$snap/NEW_FILES"

echo "change.diff: $(grep -c '^+++ ' "$out" || true) files, $(grep -c '^[+-][^+-]' "$out" || true) changed lines"

# Files whose git status changed since the snapshot but are not in the plan = possible scope creep.
if git rev-parse --git-dir >/dev/null 2>&1; then
  git status --porcelain | diff - "$snap/GIT_STATUS_BEFORE" | grep '^<' | cut -c6- | sed 's/.* -> //' | sort -u |
    while IFS= read -r f; do
      case "$f" in "$task_dir"/*|"${task_dir%/}"|docs/tasks/*|docs/CODEMAP.md) continue ;; esac
      grep -qxF "$f" "$planned" || echo "OUT_OF_PLAN: $f"
    done
fi
