#!/usr/bin/env python3
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "prepare_release.py"


def run(command, cwd, *, check=True):
    return subprocess.run(
        command,
        cwd=cwd,
        check=check,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def make_repo(root):
    app_dir = root / "apps" / "konyak"
    app_dir.mkdir(parents=True)
    (root / ".gitignore").write_text(".dart_tool/\n", encoding="utf-8")
    (app_dir / "pubspec.yaml").write_text(
        "\n".join(
            [
                "name: konyak",
                "description: Test app",
                "version: 1.0.3+4",
                "",
            ]
        ),
        encoding="utf-8",
    )
    run(["git", "init"], root)
    run(["git", "config", "user.name", "Release Test"], root)
    run(["git", "config", "user.email", "release-test@example.invalid"], root)
    run(["git", "add", "."], root)
    run(["git", "commit", "-m", "Initial"], root)


class PrepareReleaseTest(unittest.TestCase):
    def test_updates_version_commits_and_tags_after_gate_passes(self):
        with tempfile.TemporaryDirectory(prefix="konyak-prepare-release-") as raw:
            repo = Path(raw)
            make_repo(repo)

            result = run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "--repo-root",
                    str(repo),
                    "--version",
                    "1.1.0",
                    "--build-number",
                    "5",
                    "--gate",
                    "true",
                    "--commit",
                    "--tag",
                ],
                repo,
            )

            self.assertIn("Prepared release v1.1.0", result.stdout)
            self.assertEqual(
                (repo / "apps" / "konyak" / "pubspec.yaml").read_text(
                    encoding="utf-8"
                ),
                "name: konyak\n"
                "description: Test app\n"
                "version: 1.1.0+5\n",
            )
            self.assertEqual(run(["git", "status", "--short"], repo).stdout, "")
            self.assertEqual(
                run(["git", "log", "-1", "--pretty=%s"], repo).stdout.strip(),
                "Release v1.1.0",
            )
            self.assertEqual(
                run(["git", "tag", "--points-at", "HEAD"], repo).stdout.strip(),
                "v1.1.0",
            )

    def test_copies_release_notes_into_the_release_commit(self):
        with tempfile.TemporaryDirectory(prefix="konyak-prepare-release-") as raw:
            repo = Path(raw)
            make_repo(repo)
            notes = repo / ".dart_tool" / "konyak" / "release-notes-draft.md"
            notes.parent.mkdir(parents=True)
            notes.write_text(
                "## Highlights\n\n- Added the VSCode release flow.\n",
                encoding="utf-8",
            )

            run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "--repo-root",
                    str(repo),
                    "--version",
                    "1.1.0",
                    "--build-number",
                    "5",
                    "--release-notes",
                    str(notes),
                    "--gate",
                    "true",
                    "--commit",
                    "--tag",
                ],
                repo,
            )

            committed_notes = repo / "docs" / "releases" / "v1.1.0.md"
            self.assertEqual(committed_notes.read_text(encoding="utf-8"), notes.read_text(encoding="utf-8"))
            self.assertIn(
                "docs/releases/v1.1.0.md",
                run(["git", "show", "--name-only", "--pretty=", "HEAD"], repo).stdout,
            )
            self.assertEqual(run(["git", "status", "--short"], repo).stdout, "")

    def test_failed_gate_restores_pubspec_and_does_not_tag(self):
        with tempfile.TemporaryDirectory(prefix="konyak-prepare-release-") as raw:
            repo = Path(raw)
            make_repo(repo)

            result = run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "--repo-root",
                    str(repo),
                    "--bump",
                    "patch",
                    "--gate",
                    "false",
                    "--commit",
                    "--tag",
                ],
                repo,
                check=False,
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Release gate failed", result.stderr)
            self.assertIn(
                "version: 1.0.3+4",
                (repo / "apps" / "konyak" / "pubspec.yaml").read_text(
                    encoding="utf-8"
                ),
            )
            self.assertEqual(run(["git", "status", "--short"], repo).stdout, "")
            self.assertEqual(run(["git", "tag"], repo).stdout, "")

    def test_invalid_release_notes_restore_pubspec_and_do_not_tag(self):
        with tempfile.TemporaryDirectory(prefix="konyak-prepare-release-") as raw:
            repo = Path(raw)
            make_repo(repo)
            notes = repo / ".dart_tool" / "konyak" / "release-notes-draft.md"
            notes.parent.mkdir(parents=True)
            notes.write_text(" \n\t\n", encoding="utf-8")

            result = run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "--repo-root",
                    str(repo),
                    "--bump",
                    "patch",
                    "--release-notes",
                    str(notes),
                    "--gate",
                    "true",
                    "--commit",
                    "--tag",
                ],
                repo,
                check=False,
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Release notes must not be empty", result.stderr)
            self.assertIn(
                "version: 1.0.3+4",
                (repo / "apps" / "konyak" / "pubspec.yaml").read_text(
                    encoding="utf-8"
                ),
            )
            self.assertFalse((repo / "docs" / "releases" / "v1.0.4.md").exists())
            self.assertEqual(run(["git", "status", "--short"], repo).stdout, "")
            self.assertEqual(run(["git", "tag"], repo).stdout, "")


if __name__ == "__main__":
    unittest.main()
