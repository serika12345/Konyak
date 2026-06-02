from pathlib import Path
import plistlib


ROOT = Path(__file__).resolve().parents[1]


def read_text(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def require_contains(relative_path: str, expected: str) -> None:
    text = read_text(relative_path)
    if expected not in text:
        raise AssertionError(f"{relative_path} must contain: {expected}")


def require_any_contains(relative_paths: list[str], expected: str) -> None:
    for relative_path in relative_paths:
        if expected in read_text(relative_path):
            return

    joined_paths = ", ".join(relative_paths)
    raise AssertionError(f"one of {joined_paths} must contain: {expected}")


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


def require_no_files_under(relative_directory: str, glob_pattern: str) -> None:
    for path in sorted((ROOT / relative_directory).glob(glob_pattern)):
        relative_path = path.relative_to(ROOT)
        raise AssertionError(f"{relative_path} must be placed in a concern-specific folder")


def require_not_contains_under(
    relative_directory: str,
    glob_pattern: str,
    unexpected: str,
) -> None:
    for path in sorted((ROOT / relative_directory).rglob(glob_pattern)):
        text = path.read_text(encoding="utf-8")
        if unexpected in text:
            relative_path = path.relative_to(ROOT)
            raise AssertionError(f"{relative_path} must not contain: {unexpected}")


def require_io_implementation_boundaries() -> None:
    if not (ROOT / "packages/konyak_cli/lib/src").exists():
        return

    io_patterns = [
        "File(",
        "Directory(",
        "Process.",
        "HttpClient(",
        "FileSystemEntity",
        "FileSystemException",
        "ProcessException",
        "IOException",
        "SocketException",
    ]
    allowed_paths = {
        "packages/konyak_cli/lib/src/shared/common_helpers.dart",
    }
    for path in sorted((ROOT / "packages/konyak_cli/lib/src").rglob("*.dart")):
        relative_path = str(path.relative_to(ROOT))
        if relative_path.startswith("packages/konyak_cli/lib/src/io/"):
            continue
        if relative_path in allowed_paths:
            continue

        text = path.read_text(encoding="utf-8")
        for pattern in io_patterns:
            if pattern in text:
                raise AssertionError(
                    f"{relative_path} must not contain I/O pattern outside src/io: {pattern}"
                )


def require_plist_key(relative_path: str, key: str, expected: object) -> None:
    with (ROOT / relative_path).open("rb") as file:
        plist = plistlib.load(file)

    actual = plist.get(key)
    if actual != expected:
        raise AssertionError(f"{relative_path} must set {key} to {expected!r}, got {actual!r}")


def require_result_boundary_rules() -> None:
    for expected in [
        "I/O and routinely fallible business operations must return explicit",
        "CLI I/O implementations must live under `packages/konyak_cli/lib/src/io`",
        "Result/Either values or sealed result variants",
        "Expected absence in CLI/domain logic must use Option",
        "Complete-constructor invariant violations may throw",
        "must not be represented by business-logic exceptions",
        "fpdart is limited to CLI/domain code",
    ]:
        require_contains("AGENTS.md", expected)

    if (ROOT / "apps/konyak").exists():
        require_no_files_under("apps/konyak/lib/src", "*.dart")
        require_not_contains("apps/konyak/pubspec.yaml", "fpdart")
        require_not_contains_under("apps/konyak", "*.dart", "package:fpdart")
        require_contains("apps/konyak/pubspec.yaml", "fast_immutable_collections:")
        require_contains(
            "apps/konyak/lib/src/bottles/bottle_summary.dart",
            "package:fast_immutable_collections/fast_immutable_collections.dart",
        )

    if not (ROOT / "packages/konyak_cli").exists():
        return

    require_contains("packages/konyak_cli/pubspec.yaml", "fpdart:")
    require_contains(
        "packages/konyak_cli/pubspec.yaml",
        "fast_immutable_collections:",
    )
    require_contains(
        "packages/konyak_cli/lib/konyak_cli.dart",
        "package:fast_immutable_collections/fast_immutable_collections.dart",
    )
    require_contains("packages/konyak_cli/lib/konyak_cli.dart", "package:fpdart/fpdart.dart")
    require_contains("packages/konyak_cli/lib/konyak_cli.dart", "part 'src/io/io_result.dart';")
    require_no_files_under("packages/konyak_cli/lib/src", "*.dart")
    require_io_implementation_boundaries()
    require_external_payload_parser_boundaries()

    for expected in [
        "typedef IoResult<T> = Either<String, T>",
        "Either<String, T> _ioResult<T>",
        "Right<String, T>",
        "Left<String, T>",
    ]:
        require_contains("packages/konyak_cli/lib/src/io/io_result.dart", expected)

    require_contains(
        "packages/konyak_cli/lib/src/repository/repository_interfaces.dart",
        "IoResult<Option<BottleRecord>> findBottle(String id);",
    )
    require_not_contains(
        "packages/konyak_cli/lib/src/repository/repository_interfaces.dart",
        "IoResult<BottleRecord?> findBottle",
    )
    for expected in [
        "final IList<PinnedProgramRecord> pinnedPrograms;",
        "final Option<String> iconPath;",
        "Option<String> iconPath = const Option.none()",
        "iconPath.map(",
        "throw ArgumentError.value",
    ]:
        require_contains("packages/konyak_cli/lib/src/domain/bottle/bottle_models.dart", expected)
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/bottle/bottle_models.dart",
        "final String? iconPath;",
    )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/bottle/bottle_models.dart",
        "final List<PinnedProgramRecord> pinnedPrograms;",
    )
    require_contains(
        "packages/konyak_cli/lib/src/domain/program/program_settings_models.dart",
        "final IMap<String, String> environment;",
    )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/program/program_settings_models.dart",
        "final Map<String, String> environment;",
    )
    for expected in [
        "final Option<ProgramMetadataRecord> metadata;",
        "final Option<String> hostPath;",
        "Option<ProgramMetadataRecord> extract({",
        "final Option<String> architecture;",
        "final Option<String> fileDescription;",
        "final Option<String> productName;",
        "final Option<String> companyName;",
        "final Option<String> fileVersion;",
        "final Option<String> productVersion;",
        "final Option<String> iconPath;",
    ]:
        require_contains("packages/konyak_cli/lib/src/domain/program/program_catalog_models.dart", expected)
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/program/program_catalog_models.dart",
        "final String? iconPath;",
    )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/program/program_catalog_models.dart",
        "ProgramMetadataRecord? metadata",
    )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/program/program_catalog_models.dart",
        "ProgramMetadataRecord? extract",
    )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/program/program_catalog_models.dart",
        "final String? hostPath;",
    )
    for expected in [
        "final Option<String> currentVersion;",
        "final Option<String> latestVersion;",
        "final Option<String> versionUrl;",
        "final Option<String> archiveUrl;",
        "final Option<String> archiveSha256;",
        "final Option<String> sourceManifestUrl;",
        "final Option<String> sourceManifestSignatureUrl;",
    ]:
        require_contains("packages/konyak_cli/lib/src/domain/update/update_records.dart", expected)
    for forbidden in [
        "final String? currentVersion;",
        "final String? latestVersion;",
        "final String? installedVersion;",
        "final String? versionUrl;",
        "final String? archiveUrl;",
        "final String? archiveSha256;",
        "final String? sourceManifestUrl;",
        "final String? sourceManifestSignatureUrl;",
        "final String? installPath;",
    ]:
        require_not_contains("packages/konyak_cli/lib/src/domain/update/update_records.dart", forbidden)
    for expected in [
        "RuntimeInstallSource get installSource;",
        "sealed class RuntimeInstallSource",
        "final class RuntimeConfiguredArchiveSource",
        "final class RuntimeLocalArchiveSource",
        "final class RuntimeRemoteArchiveSource",
        "final class RuntimeSourceManifestInstallSource",
        "final RuntimeInstallSource installSource;",
    ]:
        require_contains(
            "packages/konyak_cli/lib/src/domain/runtime/runtime_install_operation_models.dart",
            expected,
        )
    for forbidden in [
        "String? get archivePath",
        "String? get archiveUrl",
        "String? get archiveSha256",
        "String? get sourceManifest",
        "String? get sourceManifestSignature",
        "final String? archivePath;",
        "final String? archiveUrl;",
        "final String? archiveSha256;",
        "final String? sourceManifest;",
        "final String? sourceManifestSignature;",
        "final Option<String> archivePath;",
        "final Option<String> archiveUrl;",
        "final Option<String> archiveSha256;",
        "final Option<String> sourceManifest;",
        "final Option<String> sourceManifestSignature;",
    ]:
        require_not_contains(
            "packages/konyak_cli/lib/src/domain/runtime/runtime_install_operation_models.dart",
            forbidden,
        )
    require_contains(
        "packages/konyak_cli/lib/src/domain/runtime/runtime_package_installation.dart",
        "final Option<String> archiveSha256;",
    )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/runtime/runtime_package_installation.dart",
        "final String? archiveSha256;",
    )
    require_contains(
        "packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart",
        "final Option<String> version;",
    )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart",
        "final String? version;",
    )
    for expected in [
        "final Option<String> distributionKind;",
        "final Option<bool> isInstalled;",
        "final Option<String> archiveUrl;",
        "final Option<String> versionUrl;",
        "final Option<String> applicationSupportPath;",
        "final Option<String> libraryPath;",
        "final Option<String> executablePath;",
        "final Option<RuntimeStack> stack;",
    ]:
        require_contains("packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart", expected)
    for forbidden in [
        "final String? distributionKind;",
        "final bool? isInstalled;",
        "final String? applicationSupportPath;",
        "final String? libraryPath;",
        "final String? executablePath;",
        "final String? archiveUrl;",
        "final String? versionUrl;",
        "final RuntimeStack? stack;",
    ]:
        require_not_contains("packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart", forbidden)

    result_wrapped_repository_operation_files = [
        "packages/konyak_cli/lib/src/repository/file_bottle_repository_mutation_operations.dart",
        "packages/konyak_cli/lib/src/repository/file_bottle_repository_program_operations.dart",
    ]
    for relative_path in result_wrapped_repository_operation_files:
        require_contains(relative_path, "_ioResult(")
        require_not_contains(relative_path, "throw BottleRepositoryException")
        require_not_contains(relative_path, "} on FileSystemException")
        require_not_contains(relative_path, "} on FormatException")

    for expected in [
        "class BottleCreateFailed",
        "class BottleDeleteFailed",
        "class BottleRenameFailed",
        "class BottleMoveFailed",
        "class BottleUpdateFailed",
    ]:
        require_contains("packages/konyak_cli/lib/src/domain/bottle/bottle_mutation_models.dart", expected)

    for expected in [
        "class ProgramPinFailed",
        "class ProgramUpdateFailed",
        "class ProgramSettingsReadFailed",
        "class ProgramSettingsUpdateFailed",
    ]:
        require_contains("packages/konyak_cli/lib/src/domain/program/program_mutation_models.dart", expected)

    require_contains(
        "packages/konyak_cli/lib/src/cli/cli_bottle_results.dart",
        "code: 'bottleRepositoryError'",
    )


def require_external_payload_parser_boundaries() -> None:
    cli_non_boundary_directories = [
        "packages/konyak_cli/lib/src/domain",
        "packages/konyak_cli/lib/src/platform",
        "packages/konyak_cli/lib/src/repository",
        "packages/konyak_cli/lib/src/storage",
    ]
    for relative_directory in cli_non_boundary_directories:
        for unexpected in [
            "jsonDecode(",
            "fromJson(",
            "Map<String, dynamic>",
            "List<dynamic>",
            " as Map<String",
            " as List<",
        ]:
            require_not_contains_under(relative_directory, "*.dart", unexpected)

    for relative_directory in [
        "packages/konyak_cli/lib/src/domain",
        "packages/konyak_cli/lib/src/platform",
        "packages/konyak_cli/lib/src/repository",
        "packages/konyak_cli/lib/src/storage",
    ]:
        require_not_contains_under(relative_directory, "*.dart", "Object? value")

    flutter_external_payload_boundary_paths = {
        "apps/konyak/lib/src/home_loader_parts/home_loader_platform_helpers.part.dart",
    }
    for path in sorted((ROOT / "apps/konyak/lib/src").rglob("*.dart")):
        relative_path = str(path.relative_to(ROOT))
        if relative_path.startswith("apps/konyak/lib/src/cli/"):
            continue
        if relative_path in flutter_external_payload_boundary_paths:
            continue

        text = path.read_text(encoding="utf-8")
        for unexpected in [
            "jsonDecode(",
            "Map<String, dynamic>",
            "List<dynamic>",
            " as Map<String",
            " as List<",
        ]:
            if unexpected in text:
                raise AssertionError(f"{relative_path} must not contain: {unexpected}")

    for relative_path in [
        "packages/konyak_cli/lib/src/domain/app/app_settings_models.dart",
        "packages/konyak_cli/lib/src/domain/bottle/bottle_models.dart",
        "packages/konyak_cli/lib/src/domain/bottle/bottle_runtime_settings_models.dart",
        "packages/konyak_cli/lib/src/domain/program/program_settings_models.dart",
    ]:
        require_not_contains(relative_path, "fromJson(")
        require_not_contains(relative_path, "Object? value")
        require_not_contains(relative_path, " copyWith(")

    for relative_path in [
        "apps/konyak/lib/src/bottles/bottle_summary.dart",
        "apps/konyak/lib/src/settings/app_settings_summary.dart",
    ]:
        if (ROOT / relative_path).exists():
            require_not_contains(relative_path, " copyWith(")

    for relative_path in [
        "packages/konyak_cli/lib/src/macos_pinned_launcher_manifests.dart",
        "packages/konyak_cli/lib/src/runtime_release_metadata.dart",
        "packages/konyak_cli/lib/src/runtime_release_metadata_assets.dart",
        "packages/konyak_cli/lib/src/runtime_release_metadata_source_manifests.dart",
        "packages/konyak_cli/lib/src/runtime_source_manifest_support.dart",
    ]:
        require_missing(relative_path)

    for relative_path in [
        "packages/konyak_cli/lib/src/io/app_settings_repositories.dart",
        "packages/konyak_cli/lib/src/io/macos_pinned_launcher_manifests.dart",
        "packages/konyak_cli/lib/src/io/repository_storage_io.dart",
        "packages/konyak_cli/lib/src/io/runtime_release_metadata.dart",
        "packages/konyak_cli/lib/src/io/runtime_release_metadata_assets.dart",
        "packages/konyak_cli/lib/src/io/runtime_release_metadata_source_manifests.dart",
        "packages/konyak_cli/lib/src/io/runtime_source_manifest_support.dart",
    ]:
        require_contains(relative_path, "part of '../../konyak_cli.dart';")


def main() -> None:
    require_exact(".envrc", "use flake\n")

    for expected in [
        "nix develop -c zsh -lc",
        "TDD",
        "Flutter talks to a CLI backend",
        "Wine/Proton runtimes are managed by Konyak",
        "External plist",
        "Prefer immutable data and pure functions",
        "just verify-safety",
        "Use XDG paths on Linux",
    ]:
        require_contains("AGENTS.md", expected)

    for expected in [
        "verify-safety:",
        "scripts/verify_no_invisible_chars.py",
        "scripts/verify_pub_licenses.py",
        "scripts/verify_cves.py",
    ]:
        require_contains("justfile", expected)

    for expected in [
        "osv-scanner",
    ]:
        require_contains("flake.nix", expected)
    require_contains("scripts/pub_license_policy.json", "allowedLicenses")
    require_contains("scripts/cve_audit_baseline.json", '"osv"')

    require_result_boundary_rules()

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
        "zstd",
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
    require_contains(
        "packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart",
        "RuntimeStackComponent",
    )
    runtime_support_files = [
        str(path.relative_to(ROOT))
        for path in sorted(
            (ROOT / "packages/konyak_cli/lib/src/domain/runtime").glob(
                "runtime_*support.dart"
            )
        )
    ]
    require_any_contains(runtime_support_files, "macos-konyak-runtime-stack")
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
    require_contains("docs/vscode-macos.md", "prepare_linux_dev_runtime_source.zsh")
    require_contains("docs/vscode-macos.md", "KONYAK_DEV_LINUX_WINE_STACK_MANIFEST")
    require_contains("docs/vscode-macos.md", "KONYAK_LINUX_WINE_LIBRARY_PATH")
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
        "KONYAK_DEV_LINUX_WINE_STACK_MANIFEST",
        "--dart-define=KONYAK_RUNTIME_PROFILE",
        "--dart-define=KONYAK_MACOS_WINE_HOME",
        "--dart-define=KONYAK_DEV_MACOS_WINE_STACK_MANIFEST",
    ]:
        require_contains(".vscode/launch.json", expected)
        require_contains(".vscode/tasks.json", expected)
    require_contains(".vscode/tasks.json", "scripts/prepare_linux_dev_runtime_source.zsh")
    require_contains(".vscode/launch.json", "Konyak: Prepare Linux Runtime Source")
    require_contains(
        ".vscode/launch.json", "--dart-define=KONYAK_DEV_LINUX_WINE_STACK_MANIFEST"
    )

    for expected in [
        "--dart-define=KONYAK_RUNTIME_PROFILE",
        "--dart-define=KONYAK_MACOS_WINE_HOME",
        "--dart-define=KONYAK_DEV_MACOS_WINE_STACK_MANIFEST",
    ]:
        require_contains("scripts/flutter_macos_agent_watch.py", expected)

    for expected in [
        "KONYAK_DEV_NIX_GSTREAMER_PATH",
        "prepare_macos_dev_runtime_stack.zsh",
        "KONYAK_DEV_LINUX_WINE_STACK_MANIFEST",
        "KONYAK_LINUX_WINE_LIBRARY_PATH",
    ]:
        require_contains("flake.nix", expected)
    for expected in [
        "KONYAK_DEV_LINUX_WINE_ARCHIVE",
        "KONYAK_DEV_LINUX_WINETRICKS_ARCHIVE",
        "KONYAK_DEV_LINUX_WINE_MONO_ARCHIVE",
        "KONYAK_DEV_LINUX_VKD3D_PROTON_ARCHIVE",
        "ARCHIVE_SHA256",
        "wine-mono",
        "vkd3d-proton",
    ]:
        require_contains("scripts/prepare_linux_dev_runtime_source.zsh", expected)
    require_not_contains("scripts/prepare_linux_dev_runtime_source.zsh", "winetricks list-all")
    require_not_contains("scripts/prepare_linux_dev_runtime_source.zsh", "/nix/store")
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

        cli_contract_tests = [
            str(path.relative_to(ROOT))
            for path in sorted((ROOT / "packages/konyak_cli/test").glob("cli_contract*.dart"))
        ]
        for expected in [
            "schemaVersion",
            "list-bottles",
            "inspect-bottle",
            "create-bottle",
            "rename-bottle",
            "move-bottle",
            "set-windows-version",
            "run-program",
            "list-runtimes",
        ]:
            require_any_contains(cli_contract_tests, expected)


if __name__ == "__main__":
    main()
