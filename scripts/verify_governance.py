from pathlib import Path
import plistlib


ROOT = Path(__file__).resolve().parents[1]


def read_text(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def require_contains(relative_path: str, expected: str) -> None:
    text = read_text(relative_path)
    if expected not in text:
        raise AssertionError(f"{relative_path} must contain: {expected}")


def require_not_contains(relative_path: str, unexpected: str) -> None:
    text = read_text(relative_path)
    if unexpected in text:
        raise AssertionError(f"{relative_path} must not contain: {unexpected}")


def require_exact(relative_path: str, expected: str) -> None:
    text = read_text(relative_path)
    if text != expected:
        raise AssertionError(f"{relative_path} must be exactly: {expected!r}")


def require_missing(relative_path: str) -> None:
    if (ROOT / relative_path).exists():
        raise AssertionError(f"{relative_path} must not exist in the Konyak project")


def require_plist_key(relative_path: str, key: str, expected: object) -> None:
    with (ROOT / relative_path).open("rb") as file:
        plist = plistlib.load(file)

    actual = plist.get(key)
    if actual != expected:
        raise AssertionError(f"{relative_path} must set {key} to {expected!r}, got {actual!r}")


def main() -> None:
    require_exact(".envrc", "use flake\n")

    for expected in [
        "nix develop -c zsh -lc",
        "TDD",
        "Flutter talks to a CLI backend",
        "Wine/Proton runtimes are managed by Konyak",
        "External plist",
        "Prefer immutable data and pure functions",
        "Use XDG paths on Linux",
    ]:
        require_contains("AGENTS.md", expected)

    for expected in [
        "flutter",
        "dart",
        "just",
        "deadnix",
        "statix",
        "swiftlint",
        "swiftformat",
        "gh",
        "xz",
        "[ -t 1 ]",
    ]:
        require_contains("flake.nix", expected)

    for expected in [
        "dartFlutterPackages",
        "scriptRuntimePackages",
        "verificationPackages",
        "workflowPackages",
        "linuxFlutterBuildPackages",
        "linuxReleasePackagingPackages",
        "linuxHostRuntimePackages",
        "darwinFlutterBuildPackages",
        "darwinVerificationPackages",
        "darwinDevelopmentRuntimeSourcePackages",
        "releaseBuildPackages",
        "devShellPackages",
    ]:
        require_contains("flake.nix", expected)

    for unexpected in [
        "commonPackages",
        "linuxPackages =",
        "darwinPackages =",
        "cabextract",
        "fd",
        "git-lfs",
        "melos",
        "p7zip",
        "tree",
        "unzip",
        "wineWow64Packages",
        "vkd3d-proton",
        "KONYAK_DEV_NIX_WINE_PATH",
        "KONYAK_DEV_NIX_WINETRICKS_PATH",
        "KONYAK_DEV_NIX_VKD3D_PROTON_PATH",
        "KONYAK_DEV_WINE_VERSION",
        "KONYAK_DEV_WINETRICKS_VERSION",
        "KONYAK_DEV_VKD3D_PROTON_VERSION",
        "prepare_linux_dev_runtime.zsh",
    ]:
        require_not_contains("flake.nix", unexpected)

    for expected in [
        "verify-governance",
        "format-check",
        "flutter-analyze",
        "flutter-test",
        "cli-test",
        "swift-lint",
        "macos-release",
    ]:
        require_contains("justfile", expected)

    for expected in [
        ".direnv/",
        ".dart_tool/",
        "apps/konyak/build/",
    ]:
        require_contains(".gitignore", expected)

    for expected in [
        "# Konyak",
        "manages Wine/Proton bottles",
        "apps/konyak",
        "packages/konyak_cli",
        "Konyak owns its bottle metadata",
    ]:
        require_contains("README.md", expected)

    require_contains("LICENSE", "MIT License")
    require_not_contains("LICENSE", "GNU GENERAL PUBLIC LICENSE")
    require_contains("README.md", "MIT License")
    require_not_contains("README.md", "GNU General Public License")
    require_contains(
        "THIRD_PARTY_NOTICES.md",
        "Wine/Proton runtime binaries are not bundled in Konyak application artifacts",
    )
    require_contains("THIRD_PARTY_NOTICES.md", "Wine: LGPL-2.1-or-later")
    require_contains("THIRD_PARTY_NOTICES.md", "Winetricks: LGPL-2.1")
    require_contains("THIRD_PARTY_NOTICES.md", "DXVK: zlib")
    require_contains("THIRD_PARTY_NOTICES.md", "vkd3d-proton: LGPL-2.1")
    require_contains("THIRD_PARTY_NOTICES.md", "MoltenVK: Apache-2.0")
    require_contains("THIRD_PARTY_NOTICES.md", "GStreamer: LGPL")
    require_contains("scripts/build_macos_release.zsh", "Konyak-MIT.txt")
    require_contains("scripts/build_macos_release.zsh", "THIRD_PARTY_NOTICES.md")
    require_contains("scripts/build_linux_release.zsh", "Konyak-MIT.txt")
    require_contains("scripts/build_linux_release.zsh", "THIRD_PARTY_NOTICES.md")
    require_not_contains("scripts/build_macos_release.zsh", "SOURCE-OFFER.txt")
    require_not_contains("scripts/build_linux_release.zsh", "SOURCE-OFFER.txt")
    require_not_contains("scripts/build_macos_release.zsh", "Konyak-GPL-3.0.txt")
    require_not_contains("scripts/build_linux_release.zsh", "Konyak-GPL-3.0.txt")
    require_not_contains("scripts/build_macos_release.zsh", "Konyak is distributed under GPL-3.0")
    require_not_contains("scripts/build_linux_release.zsh", "Konyak is distributed under GPL-3.0")
    require_contains(".swiftlint.yml", "SPDX-License-Identifier: MIT")
    require_not_contains(".swiftlint.yml", "GNU General Public License")
    require_contains(
        "apps/konyak/linux/runner/resources/app.konyak.Konyak.appdata.xml",
        "<project_license>MIT</project_license>",
    )
    require_not_contains(
        "apps/konyak/macos/Runner/MainFlutterWindow.swift",
        "GNU General Public License",
    )

    require_contains("CONTRIBUTING.md", "Konyak")
    require_contains("CONTRIBUTING.md", "nix develop -c zsh -lc")
    require_contains(".swiftlint.yml", "This file is part of Konyak")
    require_contains(".github/ISSUE_TEMPLATE/feature-request.yml", "Bottle metadata")
    require_not_contains(".github/ISSUE_TEMPLATE/feature-request.yml", "Bottle compatibility")

    for removed_path in [
        "Libraries/cabextract",
        "src/konyak_flutter",
        "images/cw-dark.png",
        "images/cw-light.png",
        ".github/FUNDING.yml",
        ".github/workflows/Release.yml",
        ".github/workflows/SwiftLint.yml",
        "scripts/prepare_linux_dev_runtime.zsh",
    ]:
        require_missing(removed_path)

    for expected in [
        "Konyak",
        "nix develop -c zsh -lc 'just verify'",
    ]:
        require_contains(".github/workflows/verify.yml", expected)

    for expected in [
        "Konyak Release",
        "nix run .#macos-release",
        "SHA256SUMS",
    ]:
        require_contains(".github/workflows/publish.yml", expected)
    for unexpected in [
        "MACOS_CERTIFICATE_P12_BASE64",
        "APP_STORE_CONNECT_API_KEY_BASE64",
        "notarytool",
        "KONYAK_NOTARY",
    ]:
        require_not_contains(".github/workflows/publish.yml", unexpected)
        require_not_contains("scripts/build_macos_release.zsh", unexpected)

    require_contains("docs/flutter-architecture-plan.md", "arm64 macOS")
    require_contains("docs/flutter-architecture-plan.md", "x86_64 Linux")
    require_contains(
        "docs/flutter-architecture-plan.md", "Konyak-managed Wine launch plan"
    )
    require_contains(
        "docs/flutter-architecture-plan.md", "Konyak-managed runtime stack"
    )
    require_contains("docs/flutter-architecture-plan.md", "runtime stack manifest")
    require_contains("docs/flutter-architecture-plan.md", "DXVK-macOS")
    require_contains("docs/flutter-architecture-plan.md", "GPTK/D3DMetal")
    require_contains("docs/flutter-architecture-plan.md", "TDD")
    require_not_contains("docs/flutter-architecture-plan.md", "BottleVM.plist")
    require_not_contains("docs/flutter-architecture-plan.md", "Metadata.plist")
    require_contains("docs/todo.md", "Konyak-managed macOS Wine")
    require_contains("docs/todo.md", "Konyak-managed component stack")
    require_contains("docs/todo.md", "macOS runtime stack manifest")
    require_contains("docs/todo.md", "wine64 start /unix")
    require_contains("docs/todo.md", "Gcenx/macOS_Wine_builds")
    require_contains("docs/todo.md", "Runtimes/macos-wine/bin/wine64")
    require_contains("docs/todo.md", "Drop live external plist metadata")
    require_not_contains("docs/todo.md", "BottleVM.plist")
    require_not_contains("packages/konyak_cli/lib/konyak_cli.dart", "BottleVM.plist")
    require_not_contains("packages/konyak_cli/lib/konyak_cli.dart", "Metadata.plist")
    require_contains("packages/konyak_cli/lib/konyak_cli.dart", "RuntimeStackComponent")
    require_contains("packages/konyak_cli/lib/konyak_cli.dart", "macos-konyak-runtime-stack")
    require_contains("docs/todo.md", "Linux Wine/Proton")
    require_contains("docs/cli-distribution.md", "KONYAK_CLI_EXECUTABLE")
    require_contains("docs/cli-distribution.md", "separate executables")
    require_contains("docs/release.md", "nix run .#macos-release")
    require_contains("docs/release.md", "unnotarized")
    require_contains("docs/release.md", "KONYAK_RUNTIME_STACK_SIGNING_KEY_BASE64")
    require_contains("docs/vscode-macos.md", "Konyak Flutter (macOS)")
    require_contains("docs/vscode-macos.md", "Hot Reload")
    require_contains("docs/vscode-macos.md", "Agent Edit Watch")
    require_contains("docs/vscode-macos.md", "Konyak: Flutter Run macOS (Agent Watch)")
    require_contains("docs/vscode-macos.md", ".dart_tool/konyak/flutter-sdk")
    require_contains("docs/vscode-macos.md", "prepare_macos_dev_runtime_stack.zsh")
    require_contains("docs/vscode-macos.md", "KONYAK_DEV_MACOS_WINE_STACK_MANIFEST")
    require_contains("docs/vscode-macos.md", "KONYAK_MACOS_WINE_HOME")
    require_not_contains("docs/vscode-macos.md", "Nix-provided Wine")
    require_not_contains(".vscode/tasks.json", "Prepare Linux Dev Runtime")
    require_not_contains(".vscode/tasks.json", "prepare_linux_dev_runtime.zsh")
    require_not_contains(".vscode/launch.json", "Prepare Linux Dev Runtime")

    for expected in [
        "scripts/prepare_macos_dev_runtime_stack.zsh",
        "KONYAK_RUNTIME_PROFILE",
        "KONYAK_MACOS_WINE_HOME",
        "KONYAK_DEV_MACOS_WINE_STACK_MANIFEST",
        "--dart-define=KONYAK_RUNTIME_PROFILE",
        "--dart-define=KONYAK_MACOS_WINE_HOME",
        "--dart-define=KONYAK_DEV_MACOS_WINE_STACK_MANIFEST",
    ]:
        require_contains(".vscode/launch.json", expected)
        require_contains(".vscode/tasks.json", expected)

    for expected in [
        "--dart-define=KONYAK_RUNTIME_PROFILE",
        "--dart-define=KONYAK_MACOS_WINE_HOME",
        "--dart-define=KONYAK_DEV_MACOS_WINE_STACK_MANIFEST",
    ]:
        require_contains("scripts/flutter_macos_agent_watch.py", expected)

    for expected in [
        "KONYAK_DEV_NIX_GSTREAMER_PATH",
        "prepare_macos_dev_runtime_stack.zsh",
    ]:
        require_contains("flake.nix", expected)
    require_contains("scripts/prepare_macos_dev_runtime_stack.zsh", "WINETRICKS_SCRIPT_SHA256")
    require_contains("scripts/prepare_macos_dev_runtime_stack.zsh", "winetricks list-all")
    require_not_contains(
        "scripts/prepare_macos_dev_runtime_stack.zsh",
        "KONYAK_DEV_NIX_WINETRICKS_PATH",
    )
    require_not_contains("scripts/prepare_macos_dev_runtime_stack.zsh", "konyak-dev-stub")
    require_not_contains(
        "scripts/prepare_macos_dev_runtime_stack.zsh",
        "Konyak development winetricks stub",
    )

    for expected in [
        "MACOS_ENGINE_ARTIFACTS",
        "darwin-x64",
        "resolve_bash_path()",
        "#!${bash_path}",
        "/usr/bin/env -i",
        "materialize_nix_store_symlinks",
        "/Applications/Xcode.app/Contents/Developer",
        "repair_flutter_project_permissions",
        'local macos_project="${FLUTTER_PROJECT}/macos"',
        "chmod -R u+rwX",
    ]:
        require_contains("scripts/prepare_flutter_macos_sdk.zsh", expected)

    for expected in [
        "#!/usr/bin/env zsh",
        "prepare_flutter_macos_sdk.zsh",
        'if [[ "$(uname -s)" == "Darwin" ]]; then',
        "source_flutter_root",
    ]:
        require_contains("scripts/resolve_vscode_flutter_sdk.zsh", expected)

    require_contains(
        "scripts/flutter_macos_agent_watch.py",
        'FLUTTER_PROJECT = ROOT / "apps" / "konyak"',
    )

    for expected in [
        '"Dart-Code.flutter"',
        '"mkhl.direnv"',
    ]:
        require_contains(".vscode/extensions.json", expected)

    for expected in [
        '"dart.getFlutterSdkCommand"',
        '"executable": "/bin/sh"',
        "command -v nix",
        "/run/current-system/sw/bin/nix",
        "/nix/var/nix/profiles/default/bin/nix",
        "__NIX_DARWIN_SET_ENVIRONMENT_DONE=1",
        'exec \\"$nix_bin\\" develop -c zsh -lc',
        "./scripts/resolve_vscode_flutter_sdk.zsh",
        '"dart.flutterHotReloadOnSave": "all"',
    ]:
        require_contains(".vscode/settings.json", expected)

    require_not_contains(".vscode/settings.json", '"dart.env"')

    for expected in [
        '"Konyak Flutter (macOS)"',
        '"cwd": "${workspaceFolder}/apps/konyak"',
        '"deviceId": "macos"',
        '"flutterMode": "debug"',
        '"toolArgs"',
        '"--dart-define=KONYAK_REPO_ROOT=${workspaceFolder}"',
        '"--dart-define=KONYAK_DART_EXECUTABLE=${workspaceFolder}/.dart_tool/konyak/flutter-sdk/bin/dart"',
        '"--dart-define=KONYAK_CLI_SCRIPT=${workspaceFolder}/packages/konyak_cli/bin/konyak.dart"',
        '"preLaunchTask": "Konyak: Prepare Flutter SDK macOS"',
        '"FLUTTER_ROOT": "${workspaceFolder}/.dart_tool/konyak/flutter-sdk"',
        '"KONYAK_REPO_ROOT": "${workspaceFolder}"',
        '"KONYAK_DART_EXECUTABLE": "${workspaceFolder}/.dart_tool/konyak/flutter-sdk/bin/dart"',
        '"KONYAK_CLI_SCRIPT": "${workspaceFolder}/packages/konyak_cli/bin/konyak.dart"',
        '"DEVELOPER_DIR": "/Applications/Xcode.app/Contents/Developer"',
        '"PATH": "${workspaceFolder}/.dart_tool/konyak/vscode-bin:/usr/bin:/bin:/usr/sbin:/sbin:${workspaceFolder}/.dart_tool/konyak/flutter-sdk/bin:${env:PATH}"',
    ]:
        require_contains(".vscode/launch.json", expected)

    for expected in [
        "Konyak: Prepare Flutter SDK macOS",
        "Konyak: Flutter Doctor macOS",
        "Konyak: Flutter Run macOS",
        "Konyak: Flutter Run macOS (Agent Watch)",
        "scripts/flutter_macos_agent_watch.py",
        "nix develop -c zsh -lc",
        "scripts/prepare_flutter_macos_sdk.zsh --print-sdk-path",
        "DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer",
        "KONYAK_REPO_ROOT",
        "KONYAK_DART_EXECUTABLE",
        "KONYAK_CLI_SCRIPT",
        "--dart-define=KONYAK_REPO_ROOT",
        "--dart-define=KONYAK_DART_EXECUTABLE",
        "--dart-define=KONYAK_CLI_SCRIPT",
        "$sdk/bin/flutter",
        "run -d macos",
    ]:
        require_contains(".vscode/tasks.json", expected)

    if (ROOT / "apps/konyak").exists():
        for expected in [
            "strict-casts: true",
            "strict-inference: true",
            "strict-raw-types: true",
            "avoid_dynamic_calls: true",
            "prefer_final_locals: true",
            "require_trailing_commas: true",
        ]:
            require_contains("apps/konyak/analysis_options.yaml", expected)

        require_contains("apps/konyak/pubspec.yaml", "name: konyak")
        require_contains("apps/konyak/pubspec.yaml", "description: 'Flutter desktop UI for Konyak.'")
        require_not_contains("apps/konyak/pubspec.yaml", "konyak_flutter")
        require_contains("apps/konyak/README.md", "Flutter desktop UI for Konyak.")
        require_plist_key(
            "apps/konyak/macos/Runner/DebugProfile.entitlements",
            "com.apple.security.app-sandbox",
            False,
        )
        require_plist_key(
            "apps/konyak/macos/Runner/Release.entitlements",
            "com.apple.security.app-sandbox",
            True,
        )

    if (ROOT / "packages/konyak_cli").exists():
        for expected in [
            "strict-casts: true",
            "strict-inference: true",
            "strict-raw-types: true",
            "avoid_dynamic_calls: true",
            "prefer_final_locals: true",
            "require_trailing_commas: true",
        ]:
            require_contains("packages/konyak_cli/analysis_options.yaml", expected)

        require_contains("packages/konyak_cli/test/cli_contract_test.dart", "schemaVersion")
        require_contains("packages/konyak_cli/test/cli_contract_test.dart", "list-bottles")
        require_contains("packages/konyak_cli/test/cli_contract_test.dart", "inspect-bottle")
        require_contains("packages/konyak_cli/test/cli_contract_test.dart", "create-bottle")
        require_contains("packages/konyak_cli/test/cli_contract_test.dart", "rename-bottle")
        require_contains("packages/konyak_cli/test/cli_contract_test.dart", "move-bottle")
        require_contains("packages/konyak_cli/test/cli_contract_test.dart", "set-windows-version")
        require_contains("packages/konyak_cli/test/cli_contract_test.dart", "run-program")
        require_contains("packages/konyak_cli/test/cli_contract_test.dart", "list-runtimes")


if __name__ == "__main__":
    main()
