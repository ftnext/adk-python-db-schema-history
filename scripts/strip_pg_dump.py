#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import sys


def strip_pg_dump(text: str) -> str:
    # Remove pg_dump boilerplate and keep only DDL statements.
    lines: list[str] = []
    for line in text.splitlines():
        if line.startswith("SET "):
            continue
        if line.startswith("SELECT pg_catalog.set_config("):
            continue
        if line.startswith("\\restrict ") or line.startswith("\\unrestrict "):
            continue
        if line.startswith("--"):
            continue
        lines.append(line)

    # Collapse multiple blank lines.
    out: list[str] = []
    prev_blank = False
    for line in lines:
        blank = (line.strip() == "")
        if blank and prev_blank:
            continue
        out.append(line)
        prev_blank = blank

    # Trim leading/trailing blank lines.
    while out and out[0].strip() == "":
        out.pop(0)
    while out and out[-1].strip() == "":
        out.pop()

    return "\n".join(out) + ("\n" if out else "")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: strip_pg_dump.py <version_dir>", file=sys.stderr)
        return 2

    version_dir = Path(sys.argv[1])
    if not version_dir.is_dir():
        print(f"not a directory: {version_dir}", file=sys.stderr)
        return 2

    for path in sorted(version_dir.glob("*.sql")):
        path.write_text(strip_pg_dump(path.read_text()))
        print(f"cleaned {path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
