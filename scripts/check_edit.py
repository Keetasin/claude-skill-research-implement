#!/usr/bin/env python3
"""PostToolUse hook: fast syntax check of an edited .py file. Exit 2 feeds the error back to the agent.

Compiles in memory, so no __pycache__/.pyc is written into the repo.
"""
import json
import sys

try:
    path = json.load(sys.stdin).get("tool_input", {}).get("file_path", "")
except ValueError:
    sys.exit(0)

if path.endswith(".py"):
    try:
        with open(path, encoding="utf-8") as fh:
            compile(fh.read(), path, "exec")
    except SyntaxError as err:
        print(f"syntax error: {path}:{err.lineno}: {err.msg}", file=sys.stderr)
        sys.exit(2)
    except OSError:
        sys.exit(0)
