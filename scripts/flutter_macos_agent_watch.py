#!/usr/bin/env python3
from __future__ import annotations

import errno
import json
import os
import pty
import selectors
import signal
import subprocess
import sys
import time
from collections.abc import Iterable
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FLUTTER_PROJECT = ROOT / "apps" / "konyak"
SDK_PREPARE_SCRIPT = ROOT / "scripts" / "prepare_flutter_macos_sdk.zsh"
RUNTIME_STACK_PREPARE_SCRIPT = ROOT / "scripts" / "prepare_macos_dev_runtime_stack.zsh"
DEV_RUNTIME_ROOT = ROOT / ".dart_tool" / "konyak" / "dev-runtime" / "macos-wine"
RUNTIME_RELEASE_REFERENCE = ROOT / "runtime" / "macos-wine-release.json"
POLL_SECONDS = 0.5
DEBOUNCE_SECONDS = 0.35
READY_MARKERS = (
    "Flutter run key commands.",
    'To hot reload changes while running, press "r"',
)
WATCH_PATHS = (
    FLUTTER_PROJECT / "lib",
    FLUTTER_PROJECT / "pubspec.yaml",
)


def macos_runtime_release_reference() -> dict[str, object]:
    with RUNTIME_RELEASE_REFERENCE.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise RuntimeError("macOS runtime release reference must be a JSON object")
    return data


def macos_runtime_source_manifest_url() -> str:
    reference = macos_runtime_release_reference()
    repository = (
        os.environ.get("KONYAK_DEV_MACOS_RUNTIME_RELEASE_REPO", "").strip()
        or str(reference["repository"]).strip()
    )
    release_tag = (
        os.environ.get("KONYAK_DEV_MACOS_RUNTIME_RELEASE_TAG", "").strip()
        or str(reference["defaultReleaseTag"]).strip()
    )
    manifest_name = str(reference["sourceManifestFileName"])
    if release_tag == "latest":
        return (
            f"https://github.com/{repository}/releases/latest/download/"
            f"{manifest_name}"
        )
    return (
        f"https://github.com/{repository}/releases/download/{release_tag}/"
        f"{manifest_name}"
    )


DEV_RUNTIME_STACK_MANIFEST = (
    os.environ.get("KONYAK_DEV_MACOS_WINE_STACK_MANIFEST", "").strip()
    or macos_runtime_source_manifest_url()
)


def prepare_sdk() -> Path:
    result = subprocess.run(
        [str(SDK_PREPARE_SCRIPT), "--print-sdk-path"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    lines = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    if not lines:
        raise RuntimeError("prepare_flutter_macos_sdk.zsh did not print an SDK path")
    return Path(lines[-1])


def prepare_runtime_stack(sdk: Path) -> None:
    env = os.environ.copy()
    env.update(
        {
            "KONYAK_DART_EXECUTABLE": str(sdk / "bin" / "dart"),
            "KONYAK_CLI_SCRIPT": str(
                ROOT / "packages" / "konyak_cli" / "bin" / "konyak.dart",
            ),
            "KONYAK_MACOS_WINE_HOME": str(DEV_RUNTIME_ROOT),
            "KONYAK_DEV_MACOS_WINE_STACK_MANIFEST": DEV_RUNTIME_STACK_MANIFEST,
        },
    )
    subprocess.run(
        [str(RUNTIME_STACK_PREPARE_SCRIPT), "--ensure-runtime"],
        cwd=ROOT,
        env=env,
        check=True,
        text=True,
    )


def should_watch(path: Path) -> bool:
    return path.name == "pubspec.yaml" or path.suffix == ".dart"


def iter_watch_files() -> Iterable[Path]:
    for path in WATCH_PATHS:
        if path.is_file() and should_watch(path):
            yield path
        elif path.is_dir():
            for child in path.rglob("*"):
                if child.is_file() and should_watch(child):
                    yield child


def file_signature(path: Path) -> tuple[int, int] | None:
    try:
        stat = path.stat()
    except FileNotFoundError:
        return None
    return (stat.st_mtime_ns, stat.st_size)


def snapshot() -> dict[Path, tuple[int, int] | None]:
    return {path: file_signature(path) for path in iter_watch_files()}


def changed_paths(
    before: dict[Path, tuple[int, int] | None],
    after: dict[Path, tuple[int, int] | None],
) -> list[Path]:
    paths = sorted(before.keys() | after.keys())
    return [path for path in paths if before.get(path) != after.get(path)]


def flutter_environment(sdk: Path) -> dict[str, str]:
    env = os.environ.copy()
    sdk_bin = sdk / "bin"
    env.update(
        {
            "FLUTTER_ROOT": str(sdk),
            "KONYAK_REPO_ROOT": str(ROOT),
            "KONYAK_DART_EXECUTABLE": str(sdk_bin / "dart"),
            "KONYAK_CLI_SCRIPT": str(
                ROOT / "packages" / "konyak_cli" / "bin" / "konyak.dart",
            ),
            "KONYAK_RUNTIME_PROFILE": "development",
            "KONYAK_MACOS_WINE_HOME": str(DEV_RUNTIME_ROOT),
            "KONYAK_DEV_MACOS_WINE_STACK_MANIFEST": DEV_RUNTIME_STACK_MANIFEST,
            "DEVELOPER_DIR": "/Applications/Xcode.app/Contents/Developer",
            "PATH": f"/usr/bin:/bin:/usr/sbin:/sbin:{sdk_bin}:{env.get('PATH', '')}",
        },
    )
    return env


def flutter_command(sdk: Path) -> list[str]:
    dart_executable = sdk / "bin" / "dart"
    cli_script = ROOT / "packages" / "konyak_cli" / "bin" / "konyak.dart"
    return [
        str(sdk / "bin" / "flutter"),
        "run",
        "-d",
        "macos",
        f"--dart-define=KONYAK_REPO_ROOT={ROOT}",
        f"--dart-define=KONYAK_DART_EXECUTABLE={dart_executable}",
        f"--dart-define=KONYAK_CLI_SCRIPT={cli_script}",
        "--dart-define=KONYAK_RUNTIME_PROFILE=development",
        f"--dart-define=KONYAK_MACOS_WINE_HOME={DEV_RUNTIME_ROOT}",
        f"--dart-define=KONYAK_DEV_MACOS_WINE_STACK_MANIFEST={DEV_RUNTIME_STACK_MANIFEST}",
        f"--dart-define=KONYAK_MACOS_DEV_RUNTIME_PREPARE_SCRIPT={RUNTIME_STACK_PREPARE_SCRIPT}",
    ]


def terminate_process(process: subprocess.Popen[bytes]) -> None:
    if process.poll() is not None:
        return

    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        return

    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()


def print_changed_paths(paths: list[Path]) -> None:
    rendered = ", ".join(str(path.relative_to(ROOT)) for path in paths[:4])
    if len(paths) > 4:
        rendered = f"{rendered}, ..."
    print(f"\n[konyak] File change detected: {rendered}", flush=True)


def run() -> int:
    sdk = prepare_sdk()
    prepare_runtime_stack(sdk)
    master_fd, slave_fd = pty.openpty()
    process = subprocess.Popen(
        flutter_command(sdk),
        cwd=FLUTTER_PROJECT,
        env=flutter_environment(sdk),
        stdin=slave_fd,
        stdout=slave_fd,
        stderr=slave_fd,
        start_new_session=True,
        close_fds=True,
    )
    os.close(slave_fd)

    selector = selectors.DefaultSelector()
    selector.register(master_fd, selectors.EVENT_READ, "flutter")
    if sys.stdin.isatty():
        selector.register(sys.stdin.fileno(), selectors.EVENT_READ, "stdin")

    previous_snapshot = snapshot()
    pending_paths: list[Path] = []
    first_pending_at: float | None = None
    output_tail = ""
    ready = False

    try:
        while process.poll() is None:
            for key, _ in selector.select(timeout=POLL_SECONDS):
                if key.data == "stdin":
                    stdin_data = os.read(key.fd, 4096)
                    if stdin_data:
                        os.write(master_fd, stdin_data)
                    continue

                try:
                    output = os.read(master_fd, 4096)
                except OSError as error:
                    if error.errno == errno.EIO:
                        return process.wait()
                    raise

                if not output:
                    return process.wait()

                text = output.decode(errors="replace")
                sys.stdout.write(text)
                sys.stdout.flush()
                output_tail = f"{output_tail}{text}"[-2000:]
                if any(marker in output_tail for marker in READY_MARKERS):
                    ready = True

            current_snapshot = snapshot()
            changed = changed_paths(previous_snapshot, current_snapshot)
            if changed:
                previous_snapshot = current_snapshot
                pending_paths = changed
                first_pending_at = time.monotonic()

            if (
                ready
                and pending_paths
                and first_pending_at is not None
                and time.monotonic() - first_pending_at >= DEBOUNCE_SECONDS
            ):
                print_changed_paths(pending_paths)
                print("[konyak] Sending Flutter hot reload.", flush=True)
                os.write(master_fd, b"r")
                pending_paths = []
                first_pending_at = None

        return process.wait()
    except KeyboardInterrupt:
        return 130
    finally:
        terminate_process(process)
        selector.close()
        os.close(master_fd)


def main() -> None:
    try:
        raise SystemExit(run())
    except subprocess.CalledProcessError as error:
        print(
            f"command failed with exit code {error.returncode}: {error.cmd}",
            file=sys.stderr,
        )
        raise SystemExit(error.returncode)


if __name__ == "__main__":
    main()
