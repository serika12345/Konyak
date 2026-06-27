#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


SEMVER_PATTERN = re.compile(r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$")
PUBSPEC_VERSION_PATTERN = re.compile(
    r"(?m)^version:[ \t]*([0-9]+\.[0-9]+\.[0-9]+)(?:\+([0-9]+))?[ \t]*$"
)
CLI_APP_VERSION_PATTERN = re.compile(
    r"const konyakAppVersion = (?:(?:String\.fromEnvironment\(\s*"
    r"'KONYAK_APP_VERSION',\s*defaultValue: '([0-9]+\.[0-9]+\.[0-9]+)',\s*\))"
    r"|(?:'([0-9]+\.[0-9]+\.[0-9]+)'));",
    re.MULTILINE,
)


class ReleaseError(RuntimeError):
    pass


@dataclass(frozen=True)
class AppVersion:
    name: str
    build_number: int

    @property
    def semver_tuple(self) -> tuple[int, int, int]:
        return parse_semver(self.name)

    @property
    def pubspec_value(self) -> str:
        return f"{self.name}+{self.build_number}"

    @property
    def tag(self) -> str:
        return f"v{self.name}"


def parse_semver(value: str) -> tuple[int, int, int]:
    match = SEMVER_PATTERN.fullmatch(value)
    if match is None:
        raise ReleaseError(
            f"Release version must be semantic version X.Y.Z without a leading v: {value}"
        )
    return tuple(int(part) for part in match.groups())


def parse_positive_int(value: str, label: str) -> int:
    if not re.fullmatch(r"[1-9][0-9]*", value):
        raise ReleaseError(f"{label} must be a positive integer: {value}")
    return int(value)


def read_current_version(pubspec_path: Path) -> AppVersion:
    try:
        pubspec_text = pubspec_path.read_text(encoding="utf-8")
    except FileNotFoundError as error:
        raise ReleaseError(f"Missing Flutter pubspec: {pubspec_path}") from error

    match = PUBSPEC_VERSION_PATTERN.search(pubspec_text)
    if match is None:
        raise ReleaseError(f"Missing app version in {pubspec_path}")

    build_number = int(match.group(2) or "1")
    return AppVersion(name=match.group(1), build_number=build_number)


def bump_version(current: AppVersion, bump: str) -> str:
    major, minor, patch = current.semver_tuple
    if bump == "major":
        return f"{major + 1}.0.0"
    if bump == "minor":
        return f"{major}.{minor + 1}.0"
    if bump == "patch":
        return f"{major}.{minor}.{patch + 1}"
    raise ReleaseError(f"Unsupported release bump: {bump}")


def next_version(
    current: AppVersion,
    *,
    explicit_version: str | None,
    bump: str | None,
    build_number: str | None,
) -> AppVersion:
    if explicit_version is not None:
        next_name = explicit_version
    elif bump is not None:
        next_name = bump_version(current, bump)
    else:
        raise ReleaseError("Provide either --version or --bump.")

    parse_semver(next_name)
    if parse_semver(next_name) <= current.semver_tuple:
        raise ReleaseError(
            f"Release version {next_name} must be greater than current version {current.name}."
        )

    next_build_number = (
        parse_positive_int(build_number, "--build-number")
        if build_number is not None
        else current.build_number + 1
    )
    return AppVersion(name=next_name, build_number=next_build_number)


def write_pubspec_version(pubspec_path: Path, version: AppVersion) -> str:
    original = pubspec_path.read_text(encoding="utf-8")
    updated, replacement_count = PUBSPEC_VERSION_PATTERN.subn(
        f"version: {version.pubspec_value}", original, count=1
    )
    if replacement_count != 1:
        raise ReleaseError(f"Expected exactly one app version in {pubspec_path}")
    pubspec_path.write_text(updated, encoding="utf-8")
    return original


def write_cli_app_version(model_constants_path: Path, version: AppVersion) -> str:
    try:
        original = model_constants_path.read_text(encoding="utf-8")
    except FileNotFoundError as error:
        raise ReleaseError(f"Missing CLI model constants: {model_constants_path}") from error

    updated, replacement_count = CLI_APP_VERSION_PATTERN.subn(
        "\n".join(
            [
                "const konyakAppVersion = String.fromEnvironment(",
                "  'KONYAK_APP_VERSION',",
                f"  defaultValue: '{version.name}',",
                ");",
            ]
        ),
        original,
        count=1,
    )
    if replacement_count != 1:
        raise ReleaseError(f"Expected exactly one CLI app version in {model_constants_path}")
    model_constants_path.write_text(updated, encoding="utf-8")
    return original


def restore_pubspec(pubspec_path: Path, original: str) -> None:
    pubspec_path.write_text(original, encoding="utf-8")


def restore_cli_app_version(model_constants_path: Path, original: str) -> None:
    model_constants_path.write_text(original, encoding="utf-8")


def release_notes_target(repo_root: Path, tag: str) -> Path:
    return repo_root / "docs" / "releases" / f"{tag}.md"


def copy_release_notes(source_path: Path, target_path: Path) -> bool:
    try:
        notes = source_path.read_text(encoding="utf-8")
    except FileNotFoundError as error:
        raise ReleaseError(f"Release notes file was not found: {source_path}") from error

    if not notes.strip():
        raise ReleaseError("Release notes must not be empty.")

    existed_before = target_path.exists()
    if existed_before:
        raise ReleaseError(f"Release notes already exist for this version: {target_path}")

    target_path.parent.mkdir(parents=True, exist_ok=True)
    target_path.write_text(notes, encoding="utf-8")
    return existed_before


def remove_created_release_notes(target_path: Path, existed_before: bool) -> None:
    if not existed_before and target_path.exists():
        target_path.unlink()
    if not existed_before and target_path.parent.exists():
        try:
            target_path.parent.rmdir()
        except OSError:
            pass


def run_command(
    command: list[str],
    *,
    cwd: Path,
    capture: bool = False,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=cwd,
        check=check,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )


def run_gate(command: str, *, cwd: Path) -> None:
    result = subprocess.run(
        command,
        cwd=cwd,
        shell=True,
        executable="/bin/zsh" if Path("/bin/zsh").exists() else None,
        text=True,
    )
    if result.returncode != 0:
        raise ReleaseError(f"Release gate failed: {command}")


def require_clean_worktree(repo_root: Path) -> None:
    status = run_command(
        ["git", "status", "--short", "--untracked-files=all"],
        cwd=repo_root,
        capture=True,
    ).stdout
    if status.strip():
        raise ReleaseError(
            "Release preparation requires a clean git worktree before the version update.\n"
            + status
        )


def require_missing_tag(repo_root: Path, tag: str) -> None:
    local_tag = run_command(
        ["git", "rev-parse", "--verify", "--quiet", f"refs/tags/{tag}"],
        cwd=repo_root,
        check=False,
    )
    if local_tag.returncode == 0:
        raise ReleaseError(f"Release tag already exists locally: {tag}")

    remote_url = run_command(
        ["git", "remote", "get-url", "origin"],
        cwd=repo_root,
        capture=True,
        check=False,
    )
    if remote_url.returncode != 0:
        return

    remote_tag = run_command(
        ["git", "ls-remote", "--tags", "--exit-code", "origin", f"refs/tags/{tag}"],
        cwd=repo_root,
        capture=True,
        check=False,
    )
    if remote_tag.returncode == 0:
        raise ReleaseError(f"Release tag already exists on origin: {tag}")
    if remote_tag.returncode not in (0, 2):
        raise ReleaseError(
            f"Could not check origin for existing release tag {tag}: {remote_tag.stderr}"
        )


def require_default_gates_in_dev_shell(gates: list[str]) -> None:
    if gates != ["just verify"]:
        return
    if os.environ.get("IN_NIX_SHELL"):
        return
    raise ReleaseError(
        "Default release gates must run inside the Nix dev shell. Use: "
        "nix develop -c zsh -lc 'just prepare-release --bump patch --commit --tag'"
    )


def commit_release(
    repo_root: Path,
    pubspec_path: Path,
    model_constants_path: Path,
    release_notes_path: Path | None,
    tag: str,
) -> None:
    paths = [
        str(pubspec_path.relative_to(repo_root)),
        str(model_constants_path.relative_to(repo_root)),
    ]
    if release_notes_path is not None:
        paths.append(str(release_notes_path.relative_to(repo_root)))
    run_command(["git", "add", *paths], cwd=repo_root)
    run_command(["git", "commit", "-m", f"Release {tag}"], cwd=repo_root)


def create_tag(repo_root: Path, tag: str) -> None:
    run_command(["git", "tag", "-a", tag, "-m", f"Konyak {tag.removeprefix('v')}"], cwd=repo_root)


def current_branch(repo_root: Path) -> str:
    branch = run_command(
        ["git", "branch", "--show-current"],
        cwd=repo_root,
        capture=True,
    ).stdout.strip()
    if not branch:
        raise ReleaseError("Provide --push-branch when running from detached HEAD.")
    return branch


def push_release(repo_root: Path, tag: str, branch: str | None) -> None:
    push_branch = branch or current_branch(repo_root)
    run_command(["git", "push", "origin", f"HEAD:refs/heads/{push_branch}"], cwd=repo_root)
    run_command(["git", "push", "origin", f"refs/tags/{tag}"], cwd=repo_root)


def dispatch_publish(repo_root: Path, tag: str) -> None:
    run_command(["gh", "workflow", "run", "publish.yml", "--ref", tag], cwd=repo_root)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Prepare a Konyak app release by updating the app version, running gates, and creating the release tag."
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Repository root. Defaults to the parent of scripts/.",
    )
    version_group = parser.add_mutually_exclusive_group(required=True)
    version_group.add_argument(
        "--version",
        help="Explicit app release version without a leading v, for example 1.2.0.",
    )
    version_group.add_argument(
        "--bump",
        choices=("patch", "minor", "major"),
        help="Compute the next app release version from apps/konyak/pubspec.yaml.",
    )
    parser.add_argument(
        "--build-number",
        help="Explicit Flutter build number. Defaults to the current build number plus one.",
    )
    parser.add_argument(
        "--release-notes",
        type=Path,
        help="Markdown release notes draft to copy into docs/releases/vX.Y.Z.md and include in the release commit.",
    )
    parser.add_argument(
        "--gate",
        action="append",
        help="Release gate command to run after updating pubspec and before committing/tagging. Defaults to 'just verify'.",
    )
    parser.add_argument("--commit", action="store_true", help="Commit the pubspec version update.")
    parser.add_argument("--tag", action="store_true", help="Create an annotated vX.Y.Z release tag.")
    parser.add_argument(
        "--push",
        action="store_true",
        help="Push the release commit and tag to origin. Requires --commit and --tag.",
    )
    parser.add_argument(
        "--push-branch",
        help="Remote branch name for --push. Defaults to the current local branch.",
    )
    parser.add_argument(
        "--dispatch-publish",
        action="store_true",
        help="Dispatch .github/workflows/publish.yml on the created tag. Requires --tag.",
    )
    return parser.parse_args(argv)


def prepare_release(args: argparse.Namespace) -> None:
    repo_root = args.repo_root.resolve()
    pubspec_path = repo_root / "apps" / "konyak" / "pubspec.yaml"
    model_constants_path = (
        repo_root
        / "packages"
        / "konyak_cli"
        / "lib"
        / "src"
        / "shared"
        / "model_constants.dart"
    )
    gates = args.gate or ["just verify"]
    current = read_current_version(pubspec_path)
    release = next_version(
        current,
        explicit_version=args.version,
        bump=args.bump,
        build_number=args.build_number,
    )
    tag = release.tag

    if args.tag and not args.commit:
        raise ReleaseError("--tag requires --commit so the tag points at the version update.")
    if args.push and not (args.commit and args.tag):
        raise ReleaseError("--push requires --commit and --tag.")
    if args.dispatch_publish and not args.tag:
        raise ReleaseError("--dispatch-publish requires --tag.")

    require_default_gates_in_dev_shell(gates)
    require_clean_worktree(repo_root)
    require_missing_tag(repo_root, tag)

    original_pubspec = write_pubspec_version(pubspec_path, release)
    original_model_constants = write_cli_app_version(model_constants_path, release)
    release_notes_path: Path | None = None
    release_notes_existed = False
    try:
        if args.release_notes is not None:
            release_notes_path = release_notes_target(repo_root, tag)
            release_notes_existed = copy_release_notes(
                args.release_notes.resolve(),
                release_notes_path,
            )
        for gate in gates:
            run_gate(gate, cwd=repo_root)
    except Exception:
        restore_pubspec(pubspec_path, original_pubspec)
        restore_cli_app_version(model_constants_path, original_model_constants)
        if release_notes_path is not None:
            remove_created_release_notes(release_notes_path, release_notes_existed)
        raise

    if args.commit:
        commit_release(repo_root, pubspec_path, model_constants_path, release_notes_path, tag)
    if args.tag:
        create_tag(repo_root, tag)
    if args.push:
        push_release(repo_root, tag, args.push_branch)
    if args.dispatch_publish:
        dispatch_publish(repo_root, tag)

    print(f"Prepared release {tag}.")
    print(f"Version: {current.pubspec_value} -> {release.pubspec_value}")
    if args.commit:
        print("Committed app version update.")
    if release_notes_path is not None:
        print(f"Release notes: {release_notes_path.relative_to(repo_root)}")
    if args.tag:
        print(f"Created tag: {tag}")
    if args.push:
        print("Pushed release commit and tag to origin.")
    if args.dispatch_publish:
        print("Dispatched publish.yml for the release tag.")


def main(argv: list[str]) -> int:
    try:
        prepare_release(parse_args(argv))
    except ReleaseError as error:
        print(error, file=sys.stderr)
        return 1
    except subprocess.CalledProcessError as error:
        print(f"Command failed: {' '.join(error.cmd)}", file=sys.stderr)
        if error.stdout:
            print(error.stdout, file=sys.stderr)
        if error.stderr:
            print(error.stderr, file=sys.stderr)
        return error.returncode or 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
