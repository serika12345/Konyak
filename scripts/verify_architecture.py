#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CLI_SRC = "packages/konyak_cli/lib/src/"
APP_SRC = "apps/konyak/lib/src/"


def list_git_files() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
    )
    return [path for path in result.stdout.decode("utf-8").split("\0") if path]


def read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def dart_files() -> list[str]:
    return [path for path in list_git_files() if path.endswith(".dart")]


def fail_if_contains(
    failures: list[str],
    relative_path: str,
    text: str,
    patterns: tuple[str, ...],
    message: str,
) -> None:
    for pattern in patterns:
        if pattern in text:
            failures.append(f"{relative_path}: {message}: {pattern}")


def verify_cli_domain_boundaries(failures: list[str], files: list[str]) -> None:
    forbidden_io_patterns = (
        "dart:io",
        "File(",
        "Directory(",
        "Process.",
        "Process.run",
        "Process.start",
        "HttpClient(",
        "SocketException",
        "FileSystemException",
        "ProcessException",
        "IOException",
    )
    forbidden_control_patterns = ("catch (", "catch {", "rethrow")

    for relative_path in files:
        if not relative_path.startswith(f"{CLI_SRC}domain/"):
            continue

        text = read(relative_path)
        fail_if_contains(
            failures,
            relative_path,
            text,
            forbidden_io_patterns,
            "domain code must not depend on I/O APIs",
        )
        fail_if_contains(
            failures,
            relative_path,
            text,
            forbidden_control_patterns,
            "domain code must not catch operational failures",
        )


def verify_flutter_boundaries(failures: list[str], files: list[str]) -> None:
    allowed_dart_io_paths = {
        "apps/konyak/lib/src/app/app_platform_io.dart",
        "apps/konyak/lib/src/cli/konyak_cli_client.dart",
        "apps/konyak/lib/src/cli/konyak_cli_process_runner.dart",
        "apps/konyak/lib/src/icons/icon_file_loader_io.dart",
        "apps/konyak/lib/src/logs/log_reader_io.dart",
    }
    allowed_process_paths = {
        "apps/konyak/lib/src/cli/konyak_cli_process_runner.dart",
    }

    for relative_path in files:
        if not relative_path.startswith(APP_SRC):
            continue

        text = read(relative_path)
        if "package:fpdart" in text:
            failures.append(
                f"{relative_path}: Flutter UI must not import fpdart; use app models instead"
            )
        if "dart:io" in text and relative_path not in allowed_dart_io_paths:
            failures.append(
                f"{relative_path}: dart:io must stay behind app I/O service boundaries"
            )
        if (
            ("Process.run" in text or "Process.start" in text)
            and relative_path not in allowed_process_paths
        ):
            failures.append(
                f"{relative_path}: process execution must use the CLI process runner"
            )


def verify_linux_platform_vocabulary(failures: list[str], files: list[str]) -> None:
    forbidden_macos_terms = (
        "GPTK",
        "D3DMetal",
        "Metal HUD",
        "Metal capture",
        "Rosetta",
    )
    linux_paths = (
        f"{CLI_SRC}platform/linux/",
        f"{CLI_SRC}io/linux_",
    )

    for relative_path in files:
        if not relative_path.startswith(linux_paths):
            continue

        text = read(relative_path)
        fail_if_contains(
            failures,
            relative_path,
            text,
            forbidden_macos_terms,
            "Linux implementation must not depend on macOS runtime concepts",
        )


def verify_linux_launcher_diagnostics(failures: list[str]) -> None:
    relative_path = "packages/konyak_cli/lib/src/io/linux_external_program_launchers.dart"
    if not (ROOT / relative_path).exists():
        return

    text = read(relative_path)
    required_patterns = (
        "LinuxExternalProgramLauncherDiagnosticSink",
        "LinuxExternalProgramLauncherSyncFailure",
        "diagnosticSink?.emit",
    )
    fail_if_contains(
        failures,
        relative_path,
        text,
        ("} on FileSystemException {\n      return;", "} on StateError {\n      return;"),
        "launcher sync failures must be observable",
    )
    for pattern in required_patterns:
        if pattern not in text:
            failures.append(
                f"{relative_path}: launcher sync failures must expose {pattern}"
            )


def main() -> int:
    files = dart_files()
    failures: list[str] = []
    verify_cli_domain_boundaries(failures, files)
    verify_flutter_boundaries(failures, files)
    verify_linux_platform_vocabulary(failures, files)
    verify_linux_launcher_diagnostics(failures)

    if len(failures) == 0:
        print("verify-architecture: OK")
        return 0

    print("Architecture boundary violations found:", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
