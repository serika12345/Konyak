#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
import unicodedata
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAX_SIZE = 1024 * 1024
SKIP_PREFIXES = (
    ".dart_tool/",
    ".git/",
    "apps/konyak/build/",
    "build/",
    "result/",
)


def list_git_files() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
    )
    return [path for path in result.stdout.decode("utf-8").split("\0") if path]


def is_binary(data: bytes) -> bool:
    return b"\0" in data


def is_suspicious_character(character: str) -> bool:
    codepoint = ord(character)
    if character in ("\t", "\n", "\r"):
        return False
    if 0x00 <= codepoint <= 0x1F or codepoint == 0x7F:
        return True
    return unicodedata.category(character) == "Cf"


def main() -> int:
    failures: list[str] = []
    for relative_path in list_git_files():
        if relative_path.startswith(SKIP_PREFIXES):
            continue

        path = ROOT / relative_path
        if not path.is_file() or path.stat().st_size > MAX_SIZE:
            continue

        data = path.read_bytes()
        if is_binary(data):
            continue

        text = data.decode("utf-8", errors="replace")
        for line_number, line in enumerate(text.splitlines(), start=1):
            for column, character in enumerate(line, start=1):
                if not is_suspicious_character(character):
                    continue
                codepoint = ord(character)
                name = unicodedata.name(character, "UNKNOWN")
                failures.append(
                    f"{relative_path}:{line_number}:{column} "
                    f"U+{codepoint:04X} {name}"
                )

    if len(failures) == 0:
        print("verify-no-invisible-chars: OK")
        return 0

    print("Suspicious invisible/control Unicode characters found:", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
