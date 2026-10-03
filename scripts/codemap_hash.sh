#!/usr/bin/env bash
# Short content hashes for the project code map (docs/CODEMAP.md).
# Usage:
#   codemap_hash.sh hash <file>...        print "<path>@<hash12>" per file, for section headers
#   codemap_hash.sh check <codemap.md>    print FRESH/STALE/MISSING per "<path>@<hash12>" token in the map
# Run from the repo root. A section is fresh only when every file in its header is FRESH.
set -euo pipefail

h() { sha256sum "$1" | cut -c1-12; }

case "${1:-}" in
  hash)
    shift
    for f in "$@"; do echo "$f@$(h "$f")"; done
    ;;
  check)
    map=${2:?usage: codemap_hash.sh check <codemap.md>}
    [ -f "$map" ] || { echo "no map: $map"; exit 0; }
    grep -oE '[A-Za-z0-9_./-]+@[0-9a-f]{12}' "$map" | sort -u | while IFS=@ read -r f old; do
      if [ ! -f "$f" ]; then echo "MISSING $f"
      elif [ "$(h "$f")" = "$old" ]; then echo "FRESH $f"
      else echo "STALE $f"
      fi
    done
    ;;
  *)
    echo "usage: codemap_hash.sh hash <file>... | check <codemap.md>" >&2
    exit 2
    ;;
esac
