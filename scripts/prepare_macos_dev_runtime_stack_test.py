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
        self.call_log = self.work_root / "fake-cli-calls.jsonl"
        self.fake_cli = self.work_root / "fake_cli.py"
        self.versions = {
            component_id: f"{component_id}-current" for component_id in COMPONENT_IDS
        }
        self._write_manifest()
        self._write_fake_cli()

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
