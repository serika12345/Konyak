#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
BASELINE_PATH = ROOT / "scripts/cve_audit_baseline.json"
TARGETS = (
    "apps/konyak/pubspec.lock",
    "packages/konyak_cli/pubspec.lock",
    "flake.lock",
)


def run_osv_scanner() -> dict[str, Any]:
    args = ["osv-scanner", "--format", "json", *TARGETS]
    result = subprocess.run(
        args,
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode not in (0, 1):
        raise RuntimeError(
            "osv-scanner failed: "
            + (result.stderr.strip() if result.stderr.strip() else result.stdout.strip())
        )
    if result.stdout.strip() == "":
        return {}
    return json.loads(result.stdout)


def collect_ids(value: Any) -> set[str]:
    ids: set[str] = set()
    if isinstance(value, dict):
        if isinstance(value.get("id"), str):
            ids.add(value["id"])
        if isinstance(value.get("database_specific"), dict):
            database_specific = value["database_specific"]
            if isinstance(database_specific.get("github_reviewed"), bool):
                pass
        for child in value.values():
            ids.update(collect_ids(child))
    elif isinstance(value, list):
        for child in value:
            ids.update(collect_ids(child))
    return ids


def main() -> int:
    baseline = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))
    allowed = set(baseline.get("osv", {}).get("ids", []))
    current = collect_ids(run_osv_scanner())
    unexpected = sorted(current - allowed)
    stale = sorted(allowed - current)

    if len(unexpected) > 0:
        print("CVE verification failed. Unexpected OSV advisories:", file=sys.stderr)
        for advisory_id in unexpected:
            print(f"- {advisory_id}", file=sys.stderr)
        return 1

    print(f"CVE verification passed. Tracked advisories: {len(current)}.")
    if len(stale) > 0:
        print("Baseline entries no longer reported:")
        for advisory_id in stale:
            print(f"- {advisory_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
