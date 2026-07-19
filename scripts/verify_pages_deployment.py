#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path
from urllib.parse import urljoin, urlsplit
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
RUNTIME_SCHEMA = (
    ROOT / "packages" / "konyak_cli" / "profiles" / "profile.schema.json"
)
EXPECTED_ROUTES = {
    "": b"Konyak - Wine and Proton bottle management",
    "docs/": b"Konyak documentation",
    "docs/profiles/": b"Author a compatibility profile",
    "docs/profiles/schema-v1/": b"Konyak compatibility profile",
}
SCHEMA_ROUTE = "schemas/profile-v1.schema.json"


class PagesDeploymentError(RuntimeError):
    pass


def verify_deployment(base_url: str, runtime_schema: bytes, fetch) -> None:
    normalized_base = _normalized_base_url(base_url)
    for relative_url, expected_content in EXPECTED_ROUTES.items():
        url = urljoin(normalized_base, relative_url)
        contents = fetch(url)
        if expected_content not in contents:
            raise PagesDeploymentError(
                f"deployed URL does not contain {expected_content.decode()!r}: {url}"
            )

    schema_url = urljoin(normalized_base, SCHEMA_ROUTE)
    if fetch(schema_url) != runtime_schema:
        raise PagesDeploymentError(
            "deployed profile v1 Schema must be byte-identical to the runtime Schema"
        )


def verify_with_retries(
    base_url: str,
    runtime_schema: bytes,
    *,
    attempts: int,
    delay_seconds: float,
) -> None:
    last_error: Exception | None = None
    for attempt in range(1, attempts + 1):
        try:
            verify_deployment(base_url, runtime_schema, _fetch)
            return
        except (OSError, PagesDeploymentError) as error:
            last_error = error
            if attempt < attempts:
                time.sleep(delay_seconds)
    raise PagesDeploymentError(
        f"deployment did not satisfy the public URL contract: {last_error}"
    )


def _normalized_base_url(base_url: str) -> str:
    parsed = urlsplit(base_url)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise PagesDeploymentError(f"invalid Pages base URL: {base_url}")
    return base_url.rstrip("/") + "/"


def _fetch(url: str) -> bytes:
    request = Request(url, headers={"User-Agent": "Konyak-Pages-Verification/1"})
    with urlopen(request, timeout=30) as response:
        if response.status != 200:
            raise PagesDeploymentError(
                f"deployed URL returned HTTP {response.status}: {url}"
            )
        return response.read()


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Verify the deployed Konyak Pages URL contract."
    )
    parser.add_argument("base_url")
    parser.add_argument("--schema", type=Path, default=RUNTIME_SCHEMA)
    parser.add_argument("--attempts", type=int, default=12)
    parser.add_argument("--delay-seconds", type=float, default=10)
    return parser


def main(arguments: list[str] | None = None) -> int:
    options = _parser().parse_args(arguments)
    if options.attempts < 1 or options.delay_seconds < 0:
        print("Pages deployment verification arguments are invalid.", file=sys.stderr)
        return 2
    try:
        runtime_schema = options.schema.read_bytes()
        verify_with_retries(
            options.base_url,
            runtime_schema,
            attempts=options.attempts,
            delay_seconds=options.delay_seconds,
        )
        print("Konyak Pages deployment verification passed.")
        return 0
    except (OSError, PagesDeploymentError) as error:
        print(f"Konyak Pages deployment verification failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
