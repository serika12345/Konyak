#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOCKFILES = (
    ROOT / "apps/konyak/pubspec.lock",
    ROOT / "packages/konyak_cli/pubspec.lock",
)
POLICY_PATH = ROOT / "scripts/pub_license_policy.json"


def parse_lockfile(path: Path) -> dict[str, str]:
    packages: dict[str, str] = {}
    current_name: str | None = None
    in_packages = False
    source_hosted = False
    version: str | None = None

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        if raw_line == "packages:":
            in_packages = True
            continue
        if not in_packages:
            continue

        package_match = re.match(r"^  ([A-Za-z0-9_]+):$", raw_line)
        if package_match is not None:
            if current_name is not None and source_hosted and version is not None:
                packages[current_name] = version
            current_name = package_match.group(1)
            source_hosted = False
            version = None
            continue

        if current_name is None:
            continue
        if raw_line.strip() == "source: hosted":
            source_hosted = True
        version_match = re.match(r'^    version: "([^"]+)"$', raw_line)
        if version_match is not None:
            version = version_match.group(1)

    if current_name is not None and source_hosted and version is not None:
        packages[current_name] = version

    return packages


def pub_cache_root() -> Path:
    configured = os.environ.get("PUB_CACHE")
    if configured:
        return Path(configured)
    return ROOT / ".dart_tool/pub-cache"


def license_file_for(package: str, version: str) -> Path | None:
    package_dir = pub_cache_root() / "hosted/pub.dev" / f"{package}-{version}"
    for candidate in ("LICENSE", "LICENSE.md", "LICENCE", "COPYING"):
        path = package_dir / candidate
        if path.is_file():
            return path
    return None


def classify_license(text: str) -> str | None:
    normalized = re.sub(r"\s+", " ", text.lower())
    if "apache license version 2.0" in normalized:
        return "Apache-2.0"
    if "mit license" in normalized or "permission is hereby granted, free of charge" in normalized:
        return "MIT"
    if "redistribution and use in source and binary forms" in normalized:
        if "neither the name" in normalized:
            return "BSD-3-Clause"
        return "BSD-2-Clause"
    if "isc license" in normalized:
        return "ISC"
    if "unicode license v3" in normalized:
        return "Unicode-3.0"
    return None


def main() -> int:
    policy = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
    allowed = set(policy["allowedLicenses"])
    overrides = policy.get("packageOverrides", {})
    packages: dict[str, str] = {}
    for lockfile in LOCKFILES:
        if lockfile.exists():
            packages.update(parse_lockfile(lockfile))

    failures: list[str] = []
    for package, version in sorted(packages.items()):
        override = overrides.get(package)
        license_id = override if isinstance(override, str) else None
        if license_id is None:
            license_path = license_file_for(package, version)
            if license_path is None:
                failures.append(f"{package}@{version}: license file not found in pub cache")
                continue
            license_id = classify_license(license_path.read_text(encoding="utf-8", errors="replace"))

        if license_id is None:
            failures.append(f"{package}@{version}: license could not be classified")
            continue
        if license_id not in allowed:
            failures.append(f"{package}@{version}: disallowed license {license_id}")

    if len(failures) == 0:
        print(f"Pub license verification passed for {len(packages)} packages.")
        return 0

    print("Pub license verification failed.", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
