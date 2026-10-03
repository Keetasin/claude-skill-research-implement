#!/usr/bin/env bash
# Install the skill by copying it.
# Usage: ./install.sh            -> ~/.claude/skills/research-implement
#        ./install.sh --project  -> ./.claude/skills/research-implement (run inside your project)
set -euo pipefail

src=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ "${1:-}" = "--project" ]; then
  dest="$PWD/.claude/skills/research-implement"
else
  dest="$HOME/.claude/skills/research-implement"
fi

if [ "$src" = "$dest" ]; then
  echo "already installed at $dest"
  exit 0
fi
if [ -e "$dest" ]; then
  echo "exists: $dest (remove it first to reinstall)" >&2
  exit 1
fi

mkdir -p "$dest"
cp -R "$src/SKILL.md" "$src/reference" "$src/scripts" "$src/evals" "$dest/"
chmod +x "$dest"/scripts/*.sh "$dest"/evals/*.sh
echo "installed: $dest"
echo "restart Claude Code, then run: /research-implement <task>"
echo "note: the frontmatter hook calls ~/.claude/skills/research-implement/scripts/check_edit.py; with --project, edit that path in SKILL.md"
