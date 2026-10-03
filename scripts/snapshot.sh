#!/usr/bin/env bash
# Save the "before" state of every file in the change list, including uncommitted and untracked work.
# Usage: snapshot.sh <task_dir> <file>...   (run from the repo root; paths relative to it)
# Writes <task_dir>/snapshot/<path> for existing files, lists missing ones in snapshot/NEW_FILES,
# and saves `git status --porcelain` to snapshot/GIT_STATUS_BEFORE.
# Refuses to run twice: the first snapshot is the rollback point and must not be overwritten.
set -euo pipefail

task_dir=${1:?usage: snapshot.sh <task_dir> <file>...}
shift
snap="$task_dir/snapshot"

if [ -e "$snap" ]; then
  echo "snapshot exists: $snap (keep it; it is the rollback point)" >&2
  exit 1
fi
mkdir -p "$snap"
: > "$snap/NEW_FILES"

for f in "$@"; do
  if [ -f "$f" ]; then
    mkdir -p "$snap/$(dirname "$f")"
    cp -p "$f" "$snap/$f"
  else
    echo "$f" >> "$snap/NEW_FILES"
  fi
done

git status --porcelain > "$snap/GIT_STATUS_BEFORE" 2>/dev/null || true
echo "snapshot: $(find "$snap" -type f ! -name NEW_FILES ! -name GIT_STATUS_BEFORE | wc -l) files saved, $(wc -l < "$snap/NEW_FILES") new files listed"
