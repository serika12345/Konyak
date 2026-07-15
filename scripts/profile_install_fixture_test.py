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


def shell_function(source: str, name: str) -> str:
    start = source.index(f"{name}() {{")
    end = source.index("\n}\n", start) + 2
    return source[start:end]


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
            self.assertEqual(
                profile["installerResource"]["url"],
                "https://127.0.0.1:18443/profile_fixture_installer.exe",
            )
            self.assertEqual(
                actions[1]["resource"]["url"],
                "https://127.0.0.1:18443/profile_fixture_x86.dll",
            )
            self.assertEqual(
                actions[2]["resource"]["url"],
                "https://127.0.0.1:18443/profile_fixture_x64.dll",
            )
            self.assertEqual(
                (output / ".konyak-profile-install-fixture-root").read_text(
                    encoding="utf-8"
                ),
                "konyak-profile-install-fixture-v1\n",
            )
            self.assertEqual(
                (output / "LICENSE").read_bytes(),
                (ROOT / "LICENSE").read_bytes(),
            )

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
                env={
                    **os.environ,
                    "SOURCE_DATE_EPOCH": "1",
                    "KONYAK_PROFILE_INSTALL_FIXTURE_HTTPS_PORT": "19443",
                },
            )
            self.assertEqual(second_result.returncode, 0, second_result.stderr)
            second_manifest = json.loads(
                (output / "fixture-manifest.json").read_text(encoding="utf-8")
            )
            self.assertEqual(first_manifest, second_manifest)
            second_profile = json.loads(
                (output / "profiles" / "success" / "profile.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(
                second_profile["installerResource"]["url"],
                "https://127.0.0.1:19443/profile_fixture_installer.exe",
            )

    def test_builder_rejects_unowned_and_symlink_output_roots(self) -> None:
        required = (
            "x86_64-w64-mingw32-gcc",
            "x86_64-w64-mingw32-windres",
            "i686-w64-mingw32-gcc",
        )
        missing = [command for command in required if shutil.which(command) is None]
        if missing:
            self.skipTest(f"missing Nix dev-shell tools: {', '.join(missing)}")

        with tempfile.TemporaryDirectory(prefix="konyak-profile-root-test-") as raw:
            root = Path(raw)
            unowned = root / "unowned"
            unowned.mkdir()
            sentinel = unowned / "keep.txt"
            sentinel.write_text("keep\n", encoding="utf-8")
            unowned_result = subprocess.run(
                [str(BUILD_SCRIPT), "--output", str(unowned)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(unowned_result.returncode, 64, unowned_result.stderr)
            self.assertEqual(sentinel.read_text(encoding="utf-8"), "keep\n")

            target = root / "target"
            target.mkdir()
            target_sentinel = target / "keep.txt"
            target_sentinel.write_text("keep\n", encoding="utf-8")
            symlink = root / "output-link"
            symlink.symlink_to(target, target_is_directory=True)
            symlink_result = subprocess.run(
                [str(BUILD_SCRIPT), "--output", str(symlink)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(symlink_result.returncode, 64, symlink_result.stderr)
            self.assertTrue(symlink.is_symlink())
            self.assertEqual(target_sentinel.read_text(encoding="utf-8"), "keep\n")

    def test_builder_rejects_invalid_https_port_before_creating_output(self) -> None:
        with tempfile.TemporaryDirectory(prefix="konyak-profile-port-test-") as raw:
            output = Path(raw) / "fixture"
            result = subprocess.run(
                [str(BUILD_SCRIPT), "--output", str(output)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
                env={
                    **os.environ,
                    "KONYAK_PROFILE_INSTALL_FIXTURE_HTTPS_PORT": "not-a-port",
                },
            )
            self.assertEqual(result.returncode, 64, result.stderr)
            self.assertFalse(output.exists())

    def test_destructive_root_validator_rejects_unsafe_roots(self) -> None:
        with tempfile.TemporaryDirectory(prefix="konyak-profile-validator-") as raw:
            root = Path(raw)
            fake_repo = root / "repo"
            fake_home = root / "home"
            fake_repo.mkdir()
            fake_home.mkdir()
            default_root = fake_repo / ".dart_tool" / "konyak" / "default"
            default_root.mkdir(parents=True)
            unowned = root / "unowned"
            unowned.mkdir()
            owned = root / "owned"
            owned.mkdir()
            marker_name = ".owner"
            marker_value = "fixture-owner-v1"
            (owned / marker_name).write_text(f"{marker_value}\n", encoding="utf-8")
            physical_parent = root / "physical-parent"
            physical_parent.mkdir()
            (physical_parent / "sub").mkdir()
            physical_target = physical_parent / "danger"
            physical_target.mkdir()
            (physical_target / marker_name).write_text(
                f"{marker_value}\n", encoding="utf-8"
            )
            dotdot_work = root / "dotdot-work"
            dotdot_work.mkdir()
            (dotdot_work / "hop").symlink_to(
                physical_parent / "sub", target_is_directory=True
            )
            symlink_dotdot_candidate = dotdot_work / "hop" / ".." / "danger"
            symlink_dotdot_missing_candidate = (
                dotdot_work / "hop" / ".." / "missing-danger"
            )
            dangling_target = root / "not-yet-created"
            dangling_ancestor = root / "dangling"
            dangling_ancestor.symlink_to(
                dangling_target, target_is_directory=True
            )
            dangling_candidate = dangling_ancestor / "child"
            linked = root / "linked"
            linked.symlink_to(owned, target_is_directory=True)
            missing = root / "missing"
            symlink_repo = root / "symlink-repo"
            escaped_default_parent = root / "escaped-default-parent"
            symlink_repo.mkdir()
            escaped_default_parent.mkdir()
            (symlink_repo / ".dart_tool").symlink_to(
                escaped_default_parent, target_is_directory=True
            )
            escaped_default = symlink_repo / ".dart_tool" / "konyak" / "default"
            escaped_default.resolve().mkdir(parents=True)
            internal_symlink_repo = root / "internal-symlink-repo"
            internal_escaped_parent = (
                internal_symlink_repo / "escaped-default-parent"
            )
            internal_symlink_repo.mkdir()
            internal_escaped_parent.mkdir()
            (internal_symlink_repo / ".dart_tool").symlink_to(
                internal_escaped_parent, target_is_directory=True
            )
            internal_escaped_default = (
                internal_symlink_repo / ".dart_tool" / "konyak" / "default"
            )
            internal_escaped_default.resolve().mkdir(parents=True)

            sources = {
                script_path: script_path.read_text(encoding="utf-8")
                for script_path in (BUILD_SCRIPT, SMOKE_SCRIPT)
            }
            for helper_name in (
                "resolve_physical_path_allow_missing",
                "resolve_lexical_absolute_path",
            ):
                self.assertEqual(
                    shell_function(sources[BUILD_SCRIPT], helper_name),
                    shell_function(sources[SMOKE_SCRIPT], helper_name),
                    f"{helper_name} drifted between fixture and smoke scripts",
                )

            for script_path in (BUILD_SCRIPT, SMOKE_SCRIPT):
                source = sources[script_path]
                physical_resolver = shell_function(
                    source, "resolve_physical_path_allow_missing"
                )
                lexical_resolver = shell_function(
                    source, "resolve_lexical_absolute_path"
                )
                validator = shell_function(source, "resolve_owned_destructive_root")
                function = "\n".join(
                    (physical_resolver, lexical_resolver, validator)
                )
                self.assertNotIn("realpath -m", source)
                self.assertIn(
                    'resolved_candidate="$(resolve_physical_path_allow_missing',
                    validator,
                )
                self.assertIn(
                    'lexical_default_root="$(resolve_lexical_absolute_path',
                    validator,
                )

                def validate(
                    candidate: Path | str,
                    *,
                    repository: Path = fake_repo,
                    legacy_default: Path = default_root,
                ) -> subprocess.CompletedProcess[str]:
                    return subprocess.run(
                        [
                            "zsh",
                            "-c",
                            function
                            + "\nrepo_root=\"$1\"\nHOME=\"$2\"\n"
                            + "resolve_owned_destructive_root \"$3\" \"$4\" \"$5\" \"$6\"",
                            "profile-install-root-validator",
                            str(repository),
                            str(fake_home),
                            str(candidate),
                            str(legacy_default),
                            marker_name,
                            marker_value,
                        ],
                        cwd=ROOT,
                        check=False,
                        capture_output=True,
                        text=True,
                    )

                escaped_result = validate(
                    escaped_default,
                    repository=symlink_repo,
                    legacy_default=escaped_default,
                )
                self.assertEqual(
                    escaped_result.returncode,
                    64,
                    f"{script_path.name} trusted escaped default: {escaped_result.stderr}",
                )
                internal_escaped_result = validate(
                    internal_escaped_default,
                    repository=internal_symlink_repo,
                    legacy_default=internal_escaped_default,
                )
                self.assertEqual(
                    internal_escaped_result.returncode,
                    64,
                    f"{script_path.name} trusted symlinked default: "
                    f"{internal_escaped_result.stderr}",
                )
                internal_marker = internal_escaped_default / marker_name
                internal_marker.write_text(f"{marker_value}\n", encoding="utf-8")
                owned_internal_escaped_result = validate(
                    internal_escaped_default,
                    repository=internal_symlink_repo,
                    legacy_default=internal_escaped_default,
                )
                self.assertEqual(
                    owned_internal_escaped_result.returncode,
                    0,
                    f"{script_path.name} rejected owned symlinked root: "
                    f"{owned_internal_escaped_result.stderr}",
                )
                internal_marker.unlink()
                for unsafe in (Path("/"), fake_repo, fake_home, unowned, linked):
                    result = validate(unsafe)
                    self.assertEqual(
                        result.returncode,
                        64,
                        f"{script_path.name} accepted {unsafe}: {result.stderr}",
                    )
                for safe in (default_root, owned, missing):
                    result = validate(safe)
                    self.assertEqual(
                        result.returncode,
                        0,
                        f"{script_path.name} rejected {safe}: {result.stderr}",
                    )
                symlink_dotdot_result = validate(symlink_dotdot_candidate)
                self.assertEqual(
                    symlink_dotdot_result.returncode,
                    0,
                    f"{script_path.name} rejected symlink/../ target: "
                    f"{symlink_dotdot_result.stderr}",
                )
                self.assertEqual(
                    symlink_dotdot_result.stdout.strip(),
                    str(physical_target.resolve()),
                    f"{script_path.name} changed symlink/../ resolution order",
                )
                symlink_dotdot_missing_result = validate(
                    symlink_dotdot_missing_candidate
                )
                self.assertEqual(
                    symlink_dotdot_missing_result.returncode,
                    0,
                    f"{script_path.name} rejected a missing physical leaf: "
                    f"{symlink_dotdot_missing_result.stderr}",
                )
                self.assertEqual(
                    symlink_dotdot_missing_result.stdout.strip(),
                    str(physical_parent.resolve() / "missing-danger"),
                    f"{script_path.name} changed missing-leaf resolution order",
                )
                dangling_result = validate(dangling_candidate)
                self.assertEqual(
                    dangling_result.returncode,
                    0,
                    f"{script_path.name} rejected a dangling ancestor: "
                    f"{dangling_result.stderr}",
                )
                self.assertEqual(
                    dangling_result.stdout.strip(),
                    str(root.resolve() / "not-yet-created" / "child"),
                    f"{script_path.name} did not resolve a dangling ancestor",
                )

    def test_smoke_uses_public_cli_contract_and_configurable_local_https(self) -> None:
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
        self.assertIn(
            'fixture_https_port="${KONYAK_MACOS_PROFILE_INSTALL_SMOKE_HTTPS_PORT:-18443}"',
            smoke,
        )
        self.assertIn('fixture_url="https://127.0.0.1:$fixture_https_port"', smoke)
        self.assertIn('--port "$fixture_https_port"', smoke)
        self.assertIn(
            'KONYAK_PROFILE_INSTALL_FIXTURE_HTTPS_PORT="$fixture_https_port"',
            smoke,
        )
        self.assertIn("assert_fixture_urls_match_server", smoke)
        self.assertIn("socket.bind", smoke)
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
        self.assertIn(
            'resolved_work_root="$(resolve_owned_destructive_root', smoke
        )
        self.assertIn(
            'resolved_runtime_root="$(resolve_physical_path_allow_missing', smoke
        )
        self.assertNotIn("realpath -m", smoke)
        self.assertIn('"$resolved_work_root"/*', smoke)
        self.assertIn('--arg workRoot "$work_root"', smoke)
        self.assertIn('--arg runtimeRoot "$runtime_root"', smoke)

    def test_smoke_isolates_runtime_source_and_manifest_cache(self) -> None:
        smoke = SMOKE_SCRIPT.read_text(encoding="utf-8")
        manifest_resolver = shell_function(smoke, "resolve_runtime_manifest")
        self.assertIn('runtime_source_root="$work_root/dev-runtime-source"', smoke)
        self.assertIn(
            'runtime_manifest_cache="$runtime_source_root/konyak-macos-wine-runtime-stack-source.json"',
            smoke,
        )
        self.assertIn(
            'KONYAK_DEV_MACOS_RUNTIME_SOURCE_ROOT="$runtime_source_root"', smoke
        )
        self.assertIn(
            'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST_CACHE="$runtime_manifest_cache"',
            smoke,
        )
        self.assertIn(
            'manifest_path="$(resolve_physical_path_allow_missing', smoke
        )
        self.assertIn(
            'cp "$manifest_path" "$logs_dir/runtime-source-manifest.json"', smoke
        )
        self.assertIn(
            "sha256sum runtime-source-manifest.json >runtime-source-manifest.sha256",
            smoke,
        )
        self.assertIn(
            'manifest_source="${KONYAK_DEV_MACOS_WINE_STACK_MANIFEST:-${KONYAK_MACOS_WINE_STACK_MANIFEST:-}}"',
            smoke,
        )
        self.assertIn(
            'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST="$manifest_source"', smoke
        )

        with tempfile.TemporaryDirectory(prefix="konyak-manifest-resolver-") as raw:
            root = Path(raw)
            fake_repo = root / "repo"
            scripts_dir = fake_repo / "scripts"
            scripts_dir.mkdir(parents=True)
            capture_path = root / "capture.txt"
            resolved_manifest = root / "cache" / "resolved-manifest.json"
            resolved_manifest.parent.mkdir()
            resolved_manifest.write_text("{}\n", encoding="utf-8")
            prepare_stub = scripts_dir / "prepare_macos_dev_runtime_stack.zsh"
            prepare_stub.write_text(
                "#!/usr/bin/env zsh\n"
                "set -euo pipefail\n"
                "print -r -- \"$KONYAK_DEV_MACOS_WINE_STACK_MANIFEST\" >"
                "\"$KONYAK_TEST_MANIFEST_CAPTURE\"\n"
                "print -r -- \"$KONYAK_DEV_MACOS_RUNTIME_SOURCE_ROOT\" >>"
                "\"$KONYAK_TEST_MANIFEST_CAPTURE\"\n"
                "print -r -- \"$KONYAK_DEV_MACOS_WINE_STACK_MANIFEST_CACHE\" >>"
                "\"$KONYAK_TEST_MANIFEST_CAPTURE\"\n"
                "print -r -- \"$KONYAK_TEST_RESOLVED_MANIFEST\"\n",
                encoding="utf-8",
            )
            prepare_stub.chmod(0o755)
            runtime_source_root = root / "work" / "dev-runtime-source"
            runtime_manifest_cache = runtime_source_root / "manifest.json"
            local_source = root / "explicit-manifest.json"
            local_source.write_text("{}\n", encoding="utf-8")
            for source in (
                "https://example.invalid/runtime-source.json",
                str(local_source),
                "",
            ):
                result = subprocess.run(
                    [
                        "zsh",
                        "-c",
                        manifest_resolver
                        + '\nrepo_root="$1"'
                        + '\nruntime_source_root="$2"'
                        + '\nruntime_manifest_cache="$3"'
                        + '\nresolve_runtime_manifest "$4"',
                        "profile-install-manifest-resolver",
                        str(fake_repo),
                        str(runtime_source_root),
                        str(runtime_manifest_cache),
                        source,
                    ],
                    cwd=ROOT,
                    check=False,
                    capture_output=True,
                    text=True,
                    env={
                        **os.environ,
                        "KONYAK_TEST_MANIFEST_CAPTURE": str(capture_path),
                        "KONYAK_TEST_RESOLVED_MANIFEST": str(resolved_manifest),
                    },
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), str(resolved_manifest))
                self.assertEqual(
                    capture_path.read_text(encoding="utf-8").splitlines(),
                    [source, str(runtime_source_root), str(runtime_manifest_cache)],
                )

    def test_smoke_cleanup_preserves_status_and_attempts_every_bottle(self) -> None:
        smoke = SMOKE_SCRIPT.read_text(encoding="utf-8")
        cleanup = shell_function(smoke, "cleanup")
        write_smoke_result = shell_function(smoke, "write_smoke_result")
        best_effort_terminate = shell_function(
            smoke, "best_effort_terminate_bottle"
        )
        self.assertIn("local original_exit=$?", cleanup)
        self.assertIn('for bottle_id in "${created_bottle_ids[@]}"', cleanup)
        self.assertIn("smoke-result.json", write_smoke_result)
        self.assertIn("trap cleanup EXIT", smoke)
        self.assertIn("trap 'exit 130' INT", smoke)
        self.assertIn("trap 'exit 143' TERM", smoke)
        self.assertIn("terminate-wine-processes", smoke)
        self.assertIn("cleanup-terminate-$bottle_id.result.json", smoke)
        self.assertIn('created_bottle_ids+=(profile-fixture-failure)', smoke)
        self.assertIn('created_bottle_ids+=(profile-fixture-success)', smoke)

        with tempfile.TemporaryDirectory(prefix="konyak-profile-cleanup-") as raw:
            cases = (
                ("success", 0, 0, 0, False),
                ("timeout", 124, 1, 124, True),
                ("cleanup-failure", 0, 1, 70, True),
                ("original-failure", 17, 1, 17, True),
            )
            for (
                label,
                original_status,
                termination_status,
                expected_status,
                expected_cleanup_failed,
            ) in cases:
                case_root = Path(raw) / label
                logs_dir = case_root / "logs"
                certificate_dir = case_root / "certificates"
                cleanup_log = case_root / "cleanup.log"
                logs_dir.mkdir(parents=True)
                certificate_dir.mkdir()
                command = (
                    write_smoke_result
                    + "\n"
                    + cleanup
                    + '\nbest_effort_terminate_bottle() {'
                    + '\n  print -r -- "$1" >>"$cleanup_log"'
                    + '\n  return "$termination_status"'
                    + '\n}'
                    + '\ncreated_bottle_ids=(profile-fixture-failure profile-fixture-success)'
                    + '\nhttps_server_pid=""'
                    + '\ncleanup_log="$1"'
                    + '\ncertificate_dir="$2"'
                    + '\ntermination_status="$3"'
                    + '\nlogs_dir="$4"'
                    + f"\nreturn_status={original_status}"
                    + '\nif (( return_status == 0 )); then true; else (exit "$return_status"); fi'
                    + '\ncleanup'
                )
                result = subprocess.run(
                    [
                        "zsh",
                        "-c",
                        command,
                        "profile-install-cleanup",
                        str(cleanup_log),
                        str(certificate_dir),
                        str(termination_status),
                        str(logs_dir),
                    ],
                    cwd=ROOT,
                    check=False,
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(result.returncode, expected_status, result.stderr)
                self.assertEqual(
                    cleanup_log.read_text(encoding="utf-8").splitlines(),
                    ["profile-fixture-failure", "profile-fixture-success"],
                )
                smoke_result = json.loads(
                    (logs_dir / "smoke-result.json").read_text(encoding="utf-8")
                )
                self.assertEqual(smoke_result["schemaVersion"], 1)
                self.assertTrue(smoke_result["endedAtUtc"].endswith("Z"))
                self.assertEqual(smoke_result["originalExitCode"], original_status)
                self.assertEqual(
                    smoke_result["cleanupFailed"], expected_cleanup_failed
                )
                self.assertEqual(smoke_result["exitCode"], expected_status)

            invalid_logs_path = Path(raw) / "invalid-logs-path"
            invalid_logs_path.write_text("not a directory\n", encoding="utf-8")
            for original_status, expected_status in ((0, 70), (124, 124)):
                cleanup_log = Path(raw) / f"write-failure-{original_status}.log"
                certificate_dir = Path(raw) / f"write-failure-{original_status}-certs"
                certificate_dir.mkdir()
                command = (
                    write_smoke_result
                    + "\n"
                    + cleanup
                    + '\nbest_effort_terminate_bottle() { return 0; }'
                    + '\ncreated_bottle_ids=(profile-fixture-success)'
                    + '\nhttps_server_pid=""'
                    + '\ncertificate_dir="$1"'
                    + '\nlogs_dir="$2"'
                    + f"\nreturn_status={original_status}"
                    + '\nif (( return_status == 0 )); then true; else (exit "$return_status"); fi'
                    + '\ncleanup'
                )
                result = subprocess.run(
                    [
                        "zsh",
                        "-c",
                        command,
                        "profile-install-cleanup-write-failure",
                        str(certificate_dir),
                        str(invalid_logs_path),
                    ],
                    cwd=ROOT,
                    check=False,
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(result.returncode, expected_status, result.stderr)

            logs_dir = Path(raw) / "work-root" / "logs"
            logs_dir.mkdir(parents=True)
            result = subprocess.run(
                [
                    "zsh",
                    "-c",
                    best_effort_terminate
                    + '\nrun_cli() {'
                    + '\n  captured_stdout_path="$logs_dir/$1.stdout"'
                    + '\n  captured_stderr_path="$logs_dir/$1.stderr"'
                    + '\n  captured_exit_code=0'
                    + '\n}'
                    + '\nlogs_dir="$1"'
                    + '\nfixture_root="$2"'
                    + '\ncleanup_timeout=1s'
                    + '\nactive_profile_directory="original"'
                    + '\nbest_effort_terminate_bottle profile-fixture-success',
                    "profile-install-cleanup-evidence",
                    str(logs_dir),
                    str(Path(raw) / "fixture"),
                ],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            cleanup_result = json.loads(
                (
                    logs_dir
                    / "cleanup-terminate-profile-fixture-success.result.json"
                ).read_text(encoding="utf-8")
            )
            self.assertEqual(
                cleanup_result["stdoutPath"],
                "cleanup-terminate-profile-fixture-success.stdout",
            )
            self.assertEqual(
                cleanup_result["stderrPath"],
                "cleanup-terminate-profile-fixture-success.stderr",
            )
            self.assertNotIn(str(logs_dir.parent), json.dumps(cleanup_result))

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
            'url: ($fixtureUrl + "/profile_fixture_x86.dll")',
            'url: ($fixtureUrl + "/profile_fixture_x64.dll")',
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
        self.assertIn("permissions:\n  contents: read", workflow)
        self.assertEqual(workflow.count("persist-credentials: false"), 2)
        self.assertIn(
            'KONYAK_MACOS_PROFILE_INSTALL_SMOKE_HTTPS_PORT: "18443"', workflow
        )

    def test_just_exposes_unit_build_and_smoke_targets(self) -> None:
        justfile = (ROOT / "justfile").read_text(encoding="utf-8")
        self.assertIn("profile-install-fixture-test:", justfile)
        self.assertIn("build-profile-install-fixture:", justfile)
        self.assertIn("macos-profile-install-cli-smoke:", justfile)


if __name__ == "__main__":
    unittest.main()
