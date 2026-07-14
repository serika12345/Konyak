#!/usr/bin/env python3
"""Contract tests for the synthetic profile-install fixture and smoke gate."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
BUILD_SCRIPT = ROOT / "scripts" / "build_profile_install_fixture_windows.zsh"
SMOKE_SCRIPT = ROOT / "scripts" / "run_macos_profile_install_cli_smoke.zsh"
WORKFLOW = ROOT / ".github" / "workflows" / "macos-profile-install-cli-smoke.yml"
FIXTURE_ROOT = ROOT / "tests" / "fixtures" / "windows" / "profile_install"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pe_machine(path: Path) -> int:
    payload = path.read_bytes()
    if payload[:2] != b"MZ":
        raise AssertionError(f"{path} is not a PE image")
    pe_offset = struct.unpack_from("<I", payload, 0x3C)[0]
    if payload[pe_offset : pe_offset + 4] != b"PE\0\0":
        raise AssertionError(f"{path} has no PE signature")
    return struct.unpack_from("<H", payload, pe_offset + 4)[0]


class ProfileInstallFixtureTest(unittest.TestCase):
    def test_fixture_sources_cover_installer_launcher_child_and_https(self) -> None:
        expected = {
            "installer.c",
            "launcher.c",
            "child.c",
            "native_dll.c",
            "https_server.py",
            "profile.template.json",
            "profile-bad-installer-digest.template.json",
            "profile-bad-native-digest.template.json",
            "profile-manual.template.json",
            "bad-installer-digest.error.json",
            "bad-native-digest.error.json",
        }
        self.assertTrue(FIXTURE_ROOT.is_dir())
        self.assertTrue(expected.issubset({path.name for path in FIXTURE_ROOT.iterdir()}))

        installer = (FIXTURE_ROOT / "installer.c").read_text(encoding="utf-8")
        self.assertIn("IShellLinkW", installer)
        self.assertIn("IPersistFile", installer)
        self.assertIn("FindResourceW", installer)
        launcher = (FIXTURE_ROOT / "launcher.c").read_text(encoding="utf-8")
        self.assertIn("CreateProcessW", launcher)
        self.assertIn("launcher-events.log", launcher)
        child = (FIXTURE_ROOT / "child.c").read_text(encoding="utf-8")
        self.assertIn("child-events.log", child)

    def test_builder_produces_deterministic_pe_resources_and_profiles(self) -> None:
        required = (
            "x86_64-w64-mingw32-gcc",
            "x86_64-w64-mingw32-windres",
            "i686-w64-mingw32-gcc",
        )
        missing = [command for command in required if shutil.which(command) is None]
        if missing:
            self.skipTest(f"missing Nix dev-shell tools: {', '.join(missing)}")

        with tempfile.TemporaryDirectory(prefix="konyak-profile-fixture-test-") as raw:
            output = Path(raw) / "fixture"
            result = subprocess.run(
                [str(BUILD_SCRIPT), "--output", str(output)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
                env={**os.environ, "SOURCE_DATE_EPOCH": "1"},
            )
            self.assertEqual(result.returncode, 0, result.stderr)

            installer = output / "payloads" / "profile_fixture_installer.exe"
            x86_dll = output / "payloads" / "profile_fixture_x86.dll"
            x64_dll = output / "payloads" / "profile_fixture_x64.dll"
            self.assertEqual(pe_machine(installer), 0x8664)
            self.assertEqual(pe_machine(x86_dll), 0x014C)
            self.assertEqual(pe_machine(x64_dll), 0x8664)

            smoke = SMOKE_SCRIPT.read_text(encoding="utf-8")
            function_start = smoke.index("assert_pe_machine() {")
            function_end = smoke.index(
                "\n}\n\nassert_resource_cache_clean()", function_start
            ) + 2
            focused_assertion = subprocess.run(
                [
                    "zsh",
                    "-c",
                    smoke[function_start:function_end]
                    + '\nassert_pe_machine "$1" 014c',
                    "profile-install-fixture-test",
                    str(x86_dll),
                ],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(
                focused_assertion.returncode, 0, focused_assertion.stderr
            )

            profile = json.loads(
                (output / "profiles" / "success" / "profile.json").read_text(
                    encoding="utf-8"
                )
            )
            actions = profile["preInstallActions"]
            self.assertEqual(
                [(action["kind"], action.get("componentId", action.get("verb"))) for action in actions],
                [
                    ("winetricks", "win10"),
                    ("nativeDll", "fixture-d3dcompiler-x86"),
                    ("nativeDll", "fixture-d3dcompiler-x64"),
                ],
            )
            self.assertEqual(profile["installerResource"]["sha256"], sha256(installer))
            self.assertEqual(actions[1]["resource"]["sha256"], sha256(x86_dll))
            self.assertEqual(actions[2]["resource"]["sha256"], sha256(x64_dll))
            self.assertEqual(actions[1]["machine"], "x86")
            self.assertEqual(actions[1]["destination"], "windowsSysWow64")
            self.assertEqual(actions[2]["machine"], "x64")
            self.assertEqual(actions[2]["destination"], "windowsSystem32")

            bad_installer = json.loads(
                (
                    output
                    / "profiles"
                    / "bad-installer-digest"
                    / "profile.json"
                ).read_text(encoding="utf-8")
            )
            bad_native = json.loads(
                (
                    output / "profiles" / "bad-native-digest" / "profile.json"
                ).read_text(encoding="utf-8")
            )
            self.assertNotEqual(
                bad_installer["installerResource"]["sha256"], sha256(installer)
            )
            self.assertNotEqual(
                bad_native["preInstallActions"][1]["resource"]["sha256"],
                sha256(x86_dll),
            )
            first_manifest = json.loads(
                (output / "fixture-manifest.json").read_text(encoding="utf-8")
            )
            second_result = subprocess.run(
                [str(BUILD_SCRIPT), "--output", str(output)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
                env={**os.environ, "SOURCE_DATE_EPOCH": "1"},
            )
            self.assertEqual(second_result.returncode, 0, second_result.stderr)
            second_manifest = json.loads(
                (output / "fixture-manifest.json").read_text(encoding="utf-8")
            )
            self.assertEqual(first_manifest, second_manifest)

    def test_smoke_uses_public_cli_contract_and_fixed_local_https(self) -> None:
        smoke = SMOKE_SCRIPT.read_text(encoding="utf-8")
        for command in (
            "install-macos-wine",
            "create-bottle",
            "install-program-profile",
            "apply-program-profile",
            "launch-pinned-program",
            "run-program",
            "terminate-wine-processes",
        ):
            self.assertIn(command, smoke)
        self.assertIn("CURL_CA_BUNDLE", smoke)
        self.assertIn("subjectAltName=IP:127.0.0.1", smoke)
        self.assertIn("openssl req", smoke)
        self.assertIn("https://127.0.0.1:18443", smoke)
        self.assertIn("--source-manifest", smoke)
        self.assertNotIn("WINEPREFIX", smoke)
        for forbidden in ("/bin/wine", "/bin/wine64", "/bin/wineserver", "wineloader start"):
            self.assertNotIn(forbidden, smoke)
        self.assertNotIn("local path=", smoke)
        self.assertNotIn("for path in", smoke)

    def test_smoke_runtime_root_is_resolved_below_its_isolated_work_root(self) -> None:
        smoke = SMOKE_SCRIPT.read_text(encoding="utf-8")
        self.assertIn("KONYAK_MACOS_PROFILE_INSTALL_SMOKE_RUNTIME_ROOT", smoke)
        self.assertNotIn('runtime_root="${KONYAK_MACOS_WINE_HOME', smoke)
        self.assertIn('resolved_work_root="$(realpath -m -- "$work_root")"', smoke)
        self.assertIn('resolved_runtime_root="$(realpath -m -- "$runtime_root")"', smoke)
        self.assertIn('"$resolved_work_root"/*', smoke)
        self.assertIn('--arg workRoot "$work_root"', smoke)
        self.assertIn('--arg runtimeRoot "$runtime_root"', smoke)

    def test_smoke_asserts_the_actual_cli_error_envelope(self) -> None:
        smoke = SMOKE_SCRIPT.read_text(encoding="utf-8")
        installer_error = json.loads(
            (FIXTURE_ROOT / "bad-installer-digest.error.json").read_text(
                encoding="utf-8"
            )
        )
        native_error = json.loads(
            (FIXTURE_ROOT / "bad-native-digest.error.json").read_text(
                encoding="utf-8"
            )
        )

        installer_install = installer_error["error"]["programProfileInstall"]
        native_install = native_error["error"]["programProfileInstall"]
        self.assertEqual(installer_error["error"]["code"], "profileResourceDigestMismatch")
        self.assertEqual(installer_install["stage"], "verification")
        self.assertEqual(native_error["error"]["code"], "profileResourceDigestMismatch")
        self.assertEqual(
            (
                native_install["stage"],
                native_install["actionIndex"],
                native_install["actionKind"],
                native_install["actionId"],
            ),
            ("verification", 1, "nativeDll", "fixture-d3dcompiler-x86"),
        )
        self.assertIn(".error.programProfileInstall.stage", smoke)
        self.assertIn(".error.programProfileInstall.actionIndex", smoke)
        failure_assertions = smoke[
            smoke.index("run_cli_failure bad-installer-digest") : smoke.index(
                "active_profile_directory=\"$fixture_root/profiles/success\"",
                smoke.index("run_cli_failure bad-installer-digest"),
            )
        ]
        self.assertNotIn("\n    .programProfileInstall.stage ==", failure_assertions)

    def test_smoke_checks_final_metadata_action_order_and_complete_fields(self) -> None:
        smoke = SMOKE_SCRIPT.read_text(encoding="utf-8")
        metadata_assertion = smoke[
            smoke.index("assert_profile_actions_metadata() {") :
        ]
        self.assertIn("(.bottle.profiles | length) == 1", metadata_assertion)
        self.assertIn(
            ".bottle.profiles[0].profileId == $expectedProfileId",
            metadata_assertion,
        )
        self.assertIn(
            ".bottle.profiles[0].preInstallActions", metadata_assertion
        )
        self.assertNotIn(
            'select(.profileId == "profile-install-fixture")', metadata_assertion
        )
        automatic_assertion = (
            'assert_profile_actions_metadata "$success_bottle/metadata.json" '
            'profile-install-fixture'
        )
        manual_assertion = (
            'assert_profile_actions_metadata "$success_bottle/metadata.json" '
            'profile-install-fixture-manual'
        )
        self.assertIn(automatic_assertion, smoke)
        self.assertIn(manual_assertion, smoke)
        self.assertLess(
            smoke.index(automatic_assertion),
            smoke.index('snapshot_manual_invariants "$success_bottle"'),
        )
        self.assertGreater(
            smoke.index(manual_assertion), smoke.index("run_cli_success manual-apply")
        )
        automatic_copy = '"$logs_dir/profile-fixture-success.auto.metadata.json"'
        manual_copy = '"$logs_dir/profile-fixture-success.manual.metadata.json"'
        self.assertIn(automatic_copy, smoke)
        self.assertIn(manual_copy, smoke)
        self.assertLess(smoke.index(automatic_assertion), smoke.index(automatic_copy))
        self.assertLess(
            smoke.index(automatic_copy), smoke.index("run_cli_success manual-apply")
        )
        self.assertLess(smoke.index(manual_assertion), smoke.index(manual_copy))
        for expected in (
            '{kind: "winetricks", verb: "win10"}',
            'componentId: "fixture-d3dcompiler-x86"',
            'machine: "x86"',
            'destination: "windowsSysWow64"',
            'componentId: "fixture-d3dcompiler-x64"',
            'machine: "x64"',
            'destination: "windowsSystem32"',
            'targetFileName: "d3dcompiler_47.dll"',
            'url: "https://127.0.0.1:18443/profile_fixture_x86.dll"',
            'url: "https://127.0.0.1:18443/profile_fixture_x64.dll"',
            "sha256: $x86Digest",
            "sha256: $x64Digest",
        ):
            self.assertIn(expected, metadata_assertion)

    def test_workflow_keeps_fixture_build_and_runtime_smoke_rerunnable(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("build-profile-install-fixture:", workflow)
        self.assertIn("runs-on: ubuntu-24.04", workflow)
        self.assertIn("profile-install-cli-smoke:", workflow)
        self.assertIn("needs: build-profile-install-fixture", workflow)
        self.assertIn("actions/upload-artifact@v4", workflow)
        self.assertIn("if: always()", workflow)
        self.assertNotIn("build-wine-runtime", workflow)
        self.assertIn("run_macos_profile_install_cli_smoke.zsh", workflow)

    def test_just_exposes_unit_build_and_smoke_targets(self) -> None:
        justfile = (ROOT / "justfile").read_text(encoding="utf-8")
        self.assertIn("profile-install-fixture-test:", justfile)
        self.assertIn("build-profile-install-fixture:", justfile)
        self.assertIn("macos-profile-install-cli-smoke:", justfile)


if __name__ == "__main__":
    unittest.main()
