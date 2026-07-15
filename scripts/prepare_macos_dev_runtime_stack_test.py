#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PREPARE_SCRIPT = ROOT / "scripts" / "prepare_macos_dev_runtime_stack.zsh"
COMPONENT_IDS = (
    "wine",
    "dxvk-macos",
    "moltenvk",
    "gstreamer",
    "freetype",
    "wine-mono",
    "wine-gecko",
    "winetricks",
    "vkd3d",
    "dxmt",
)


class PrepareMacosDevRuntimeStackTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.work_root = Path(self.temporary_directory.name)
        self.runtime_root = self.work_root / "runtime"
        self.manifest_path = self.work_root / "manifest.json"
        self.manifest_cache = self.work_root / "cache" / "manifest.json"
        self.call_log = self.work_root / "fake-cli-calls.jsonl"
        self.fake_curl_log = self.work_root / "fake-curl-source.txt"
        self.fake_bin = self.work_root / "fake-bin"
        self.fake_cli = self.work_root / "fake_cli.py"
        self.versions = {
            component_id: f"{component_id}-current" for component_id in COMPONENT_IDS
        }
        self._write_manifest()
        self._write_fake_cli()
        self._write_fake_curl()

    def _write_manifest(self) -> None:
        components = [
            {
                "id": component_id,
                "version": version,
                "archiveUrl": "https://example.invalid/runtime.tar.zst",
                "sha256": "a" * 64,
            }
            for component_id, version in self.versions.items()
        ]
        self.manifest_path.write_text(
            json.dumps(
                {
                    "schemaVersion": 1,
                    "runtimeId": "konyak-macos-wine",
                    "stackId": "macos-konyak-runtime-stack",
                    "components": components,
                }
            ),
            encoding="utf-8",
        )

    def _write_fake_cli(self) -> None:
        self.fake_cli.write_text(
            """#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path

arguments = sys.argv[1:]
if not arguments or arguments[0] != "install-macos-wine":
    raise SystemExit(f"unexpected fake CLI arguments: {arguments}")
manifest_path = Path(arguments[arguments.index("--source-manifest") + 1])
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
runtime_root = Path(os.environ["KONYAK_MACOS_WINE_HOME"])
(runtime_root / "bin").mkdir(parents=True, exist_ok=True)
wineloader = runtime_root / "bin" / "wineloader"
wineloader.write_text("fake wineloader", encoding="utf-8")
wineloader.chmod(0o755)
(runtime_root / ".konyak-runtime-stack.json").write_text(
    json.dumps(
        {
            "schemaVersion": 1,
            "components": {
                component["id"]: component["version"]
                for component in manifest["components"]
            },
        }
    ),
    encoding="utf-8",
)
with Path(os.environ["KONYAK_TEST_FAKE_CLI_CALL_LOG"]).open(
    "a", encoding="utf-8"
) as handle:
    handle.write(json.dumps(arguments) + "\\n")
print(json.dumps({"schemaVersion": 1, "runtime": {"isInstalled": True}}))
""",
            encoding="utf-8",
        )

    def _write_fake_curl(self) -> None:
        self.fake_bin.mkdir()
        fake_curl = self.fake_bin / "curl"
        fake_curl.write_text(
            """#!/usr/bin/env python3
import os
import shutil
import sys
from pathlib import Path

arguments = sys.argv[1:]
output_path = Path(arguments[arguments.index("--output") + 1])
shutil.copyfile(os.environ["KONYAK_TEST_REMOTE_MANIFEST"], output_path)
Path(os.environ["KONYAK_TEST_FAKE_CURL_LOG"]).write_text(
    arguments[-1], encoding="utf-8"
)
""",
            encoding="utf-8",
        )
        fake_curl.chmod(0o755)

    def _default_manifest_source(self) -> str:
        reference = json.loads(
            (ROOT / "runtime" / "macos-wine-release.json").read_text(
                encoding="utf-8"
            )
        )
        return (
            f"https://github.com/{reference['repository']}/releases/latest/download/"
            f"{reference['sourceManifestFileName']}"
        )

    def _environment(self) -> dict[str, str]:
        environment = os.environ.copy()
        environment.update(
            {
                "KONYAK_DART_EXECUTABLE": sys.executable,
                "KONYAK_CLI_SCRIPT": str(self.fake_cli),
                "KONYAK_MACOS_WINE_HOME": str(self.runtime_root),
                "KONYAK_DEV_MACOS_WINE_STACK_MANIFEST": str(self.manifest_path),
                "KONYAK_TEST_FAKE_CLI_CALL_LOG": str(self.call_log),
            }
        )
        return environment

    def _run_prepare(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                str(PREPARE_SCRIPT),
                "--ensure-runtime",
                "--print-manifest-path",
            ],
            cwd=ROOT,
            env=self._environment(),
            check=True,
            capture_output=True,
            text=True,
        )

    def _fake_cli_call_count(self) -> int:
        if not self.call_log.exists():
            return 0
        return len(self.call_log.read_text(encoding="utf-8").splitlines())

    def test_installs_missing_runtime_once_and_skips_current_runtime(self) -> None:
        first = self._run_prepare()

        self.assertEqual(first.stdout.strip(), str(self.manifest_path))
        self.assertEqual(self._fake_cli_call_count(), 1)

        second = self._run_prepare()

        self.assertEqual(second.stdout.strip(), str(self.manifest_path))
        self.assertEqual(self._fake_cli_call_count(), 1)
        self.assertIn("development runtime is current", second.stderr)

    def test_prints_selected_manifest_source_without_exposing_cache_path(self) -> None:
        result = subprocess.run(
            [str(PREPARE_SCRIPT), "--print-manifest-source"],
            cwd=ROOT,
            env=self._environment(),
            check=True,
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.stdout.strip(), str(self.manifest_path))

    def test_trims_configured_manifest_source(self) -> None:
        environment = self._environment()
        environment["KONYAK_DEV_MACOS_WINE_STACK_MANIFEST"] = (
            f" \t{self.manifest_path}\n "
        )

        result = subprocess.run(
            [str(PREPARE_SCRIPT), "--print-manifest-source"],
            cwd=ROOT,
            env=environment,
            check=True,
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.stdout.strip(), str(self.manifest_path))

    def test_blank_manifest_source_uses_repository_latest(self) -> None:
        environment = self._environment()
        environment.update(
            {
                "PATH": f"{self.fake_bin}:{environment['PATH']}",
                "KONYAK_DEV_MACOS_WINE_STACK_MANIFEST": " \t\n ",
                "KONYAK_DEV_MACOS_WINE_STACK_MANIFEST_CACHE": str(
                    self.manifest_cache
                ),
                "KONYAK_TEST_REMOTE_MANIFEST": str(self.manifest_path),
                "KONYAK_TEST_FAKE_CURL_LOG": str(self.fake_curl_log),
            }
        )

        result = subprocess.run(
            [str(PREPARE_SCRIPT), "--print-manifest-source"],
            cwd=ROOT,
            env=environment,
            check=True,
            capture_output=True,
            text=True,
        )

        expected_source = self._default_manifest_source()
        self.assertEqual(result.stdout.strip(), expected_source)
        self.assertEqual(
            self.fake_curl_log.read_text(encoding="utf-8"), expected_source
        )

    @unittest.skipUnless(
        sys.platform == "darwin",
        "the macOS development-shell manifest contract is Darwin-only",
    )
    def test_dev_shell_normalizes_manifest_override(self) -> None:
        cases = (
            (" \t\n ", self._default_manifest_source()),
            (
                " \thttps://example.invalid/pinned-source.json\n ",
                "https://example.invalid/pinned-source.json",
            ),
        )

        for override, expected_source in cases:
            with self.subTest(override=override):
                environment = os.environ.copy()
                environment["KONYAK_MACOS_WINE_STACK_MANIFEST_OVERRIDE"] = override
                result = subprocess.run(
                    [
                        "nix",
                        "develop",
                        "-c",
                        "zsh",
                        "-lc",
                        'print -rn -- "$KONYAK_DEV_MACOS_WINE_STACK_MANIFEST"',
                    ],
                    cwd=ROOT,
                    env=environment,
                    check=True,
                    capture_output=True,
                    text=True,
                )

                self.assertEqual(result.stdout, expected_source)

    def test_updates_stale_runtime_but_allows_additional_components(self) -> None:
        installed_versions = dict(self.versions)
        installed_versions["wine"] = "wine-stale"
        installed_versions["gptk-d3dmetal"] = "developer-import"
        (self.runtime_root / "bin").mkdir(parents=True)
        wineloader = self.runtime_root / "bin" / "wineloader"
        wineloader.write_text("fake wineloader", encoding="utf-8")
        wineloader.chmod(0o755)
        (self.runtime_root / ".konyak-runtime-stack.json").write_text(
            json.dumps({"schemaVersion": 1, "components": installed_versions}),
            encoding="utf-8",
        )

        self._run_prepare()
        self.assertEqual(self._fake_cli_call_count(), 1)

        metadata = json.loads(
            (self.runtime_root / ".konyak-runtime-stack.json").read_text(
                encoding="utf-8"
            )
        )
        metadata["components"]["gptk-d3dmetal"] = "developer-import"
        (self.runtime_root / ".konyak-runtime-stack.json").write_text(
            json.dumps(metadata), encoding="utf-8"
        )

        self._run_prepare()
        self.assertEqual(self._fake_cli_call_count(), 1)


if __name__ == "__main__":
    unittest.main()
