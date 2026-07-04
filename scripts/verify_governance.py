from pathlib import Path
import plistlib
import re


ROOT = Path(__file__).resolve().parents[1]
REMOVED_CLI_BACKEND = "packages/konyak_cli/lib/src/io/konyak_cli_backend.dart"

PRODUCTION_DART_ROOTS = [
    "packages/konyak_cli/lib",
    "apps/konyak/lib",
]

PRODUCTION_LINE_LIMIT_BASELINE = {
    "apps/konyak/lib/src/l10n/konyak_localizations.dart": "Flutter generated localization API",
    "packages/konyak_cli/lib/src/domain/shared/domain_value_objects.dart": (
        "Freezed value object declarations are intentionally centralized"
    ),
}

REFACTORING_FILE_GROWTH_LIMITS = {
    "packages/konyak_cli/lib/src/domain/program/program_runner.dart": (
        450,
        "program planner domain logic must stay split into focused helpers",
    ),
    "apps/konyak/lib/src/home_loader/home_loader.dart": (
        420,
        "home loader orchestration must not absorb extracted state helpers",
    ),
    "apps/konyak/lib/src/home_loader/home_loader_bottles.dart": (
        520,
        "bottle loader workflows must not absorb extracted state helpers",
    ),
    "apps/konyak/lib/src/home_loader/home_loader_programs.dart": (
        600,
        "program loader workflows must remain extension-scoped",
    ),
    "apps/konyak/lib/src/home_loader/home_loader_runtimes.dart": (
        760,
        "runtime loader workflows must remain extension-scoped",
    ),
}

KONYAK_CLI_PUBLIC_EXPORT_LINES = [
    "export 'src/cli/cli_facade.dart' show runCli, runCliStreaming;",
    "export 'src/cli/cli_result_model.dart' show CliResult;",
    "export 'src/domain/app/app_settings_models.dart';",
    "export 'src/domain/bottle/bottle_models.dart';",
    "export 'src/domain/bottle/bottle_mutation_models.dart';",
    "export 'src/domain/bottle/bottle_runtime_settings_models.dart';",
    "export 'src/domain/program/pinned_programs.dart';",
    "export 'src/domain/program/program_argument_support.dart';",
    "export 'src/domain/program/program_catalog_models.dart';",
    "export 'src/domain/program/program_graphics_backend_hints.dart';",
    "export 'src/domain/program/program_mutation_models.dart';",
    "export 'src/domain/program/program_registry_models.dart';",
    "export 'src/domain/program/program_registry_plans.dart';",
    "export 'src/domain/program/program_run_environment.dart';",
    "export 'src/domain/program/program_run_models.dart';",
    "export 'src/domain/program/program_runner.dart';",
    "export 'src/domain/program/program_settings_models.dart';",
    "export 'src/domain/runtime/host_environment.dart';",
    "export 'src/domain/runtime/runtime_catalogs.dart';",
    "export 'src/domain/runtime/runtime_component_versions.dart';",
    "export 'src/domain/runtime/runtime_install_operation_models.dart';",
    "export 'src/domain/runtime/runtime_install_plans.dart';",
    "export 'src/domain/runtime/runtime_models.dart';",
    "export 'src/domain/runtime/runtime_package_installation.dart';",
    "export 'src/domain/runtime/runtime_platform_support.dart';",
    "export 'src/domain/runtime/runtime_profile_environment.dart';",
    "export 'src/domain/runtime/runtime_source_archive_planning.dart';",
    "export 'src/domain/runtime/runtime_source_bundle_models.dart';",
    "export 'src/domain/runtime/runtime_update_checker.dart';",
    "export 'src/domain/runtime/runtime_update_support.dart';",
    "export 'src/domain/runtime/runtime_validation.dart';",
    "export 'src/domain/runtime/runtime_validation_models.dart';",
    "export 'src/domain/runtime/runtime_validation_support.dart';",
    "export 'src/domain/runtime/wine_runtime_paths.dart';",
    "export 'src/domain/shared/domain_value_objects.dart';",
    "export 'src/domain/update/app_update_checker.dart';",
    "export 'src/domain/update/update_records.dart';",
    "export 'src/domain/update/updates.dart';",
]

CUSTOM_LINT_RULES = [
    "konyak_no_domain_increment",
    "konyak_no_domain_io",
    "konyak_no_domain_nested_conditional",
    "konyak_no_domain_parameter_mutation",
    "konyak_no_domain_part_of_root",
    "konyak_no_domain_reassignment",
    "konyak_no_domain_var_declaration",
    "konyak_no_handwritten_part",
    "konyak_no_null_literal_outside_boundary",
    "konyak_no_nullable_bridge_outside_boundary",
    "konyak_no_nullable_cli_command_handler",
    "konyak_no_nullable_sentinel_flow",
    "konyak_no_nullable_type_outside_boundary",
    "konyak_no_result_failure_to_option_none",
]


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


def require_section_contains(relative_path: str, marker: str, expected: str) -> None:
    section = read_section(relative_path, marker)
    if expected not in section:
        raise AssertionError(f"{relative_path} section {marker} must contain: {expected}")


def require_section_not_contains(relative_path: str, marker: str, unexpected: str) -> None:
    section = read_section(relative_path, marker)
    if unexpected in section:
        raise AssertionError(f"{relative_path} section {marker} must not contain: {unexpected}")


def read_section(relative_path: str, marker: str) -> str:
    text = read_text(relative_path)
    start = text.find(marker)
    if start == -1:
        raise AssertionError(f"{relative_path} must contain section marker: {marker}")

    next_marker = text.find("// ---- ", start + len(marker))
    if next_marker == -1:
        return text[start:]
    return text[start:next_marker]


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


def require_no_handwritten_parts() -> None:
    allowed_part_suffixes = (".freezed.dart';", '.g.dart";', ".g.dart';")
    for relative_directory in ["packages/konyak_cli/lib", "apps/konyak/lib"]:
        for path in sorted((ROOT / relative_directory).rglob("*.dart")):
            relative_path = str(path.relative_to(ROOT))
            if relative_path.endswith(".freezed.dart") or relative_path.endswith(".g.dart"):
                continue

            for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                stripped = line.strip()
                if stripped.startswith("part of "):
                    raise AssertionError(
                        f"{relative_path}:{line_number} must not use hand-written part of"
                    )
                if stripped.startswith("part ") and not stripped.endswith(allowed_part_suffixes):
                    raise AssertionError(
                        f"{relative_path}:{line_number} must not use hand-written part"
                    )


def production_dart_files() -> list[Path]:
    files: list[Path] = []
    for relative_directory in PRODUCTION_DART_ROOTS:
        root = ROOT / relative_directory
        if not root.exists():
            continue
        files.extend(
            path
            for path in sorted(root.rglob("*.dart"))
            if not str(path).endswith(".freezed.dart")
            and not str(path).endswith(".g.dart")
        )
    return files


def require_no_transitional_part_paste_markers() -> None:
    marker_pattern = re.compile(r"^// ---- .+\.dart ----$")
    for path in production_dart_files():
        relative_path = str(path.relative_to(ROOT))
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if marker_pattern.match(line):
                raise AssertionError(
                    f"{relative_path}:{line_number} must not paste old part files with section markers"
                )


def require_production_file_line_limits() -> None:
    for path in production_dart_files():
        relative_path = str(path.relative_to(ROOT))
        line_count = len(path.read_text(encoding="utf-8").splitlines())
        if line_count <= 1000:
            continue
        if relative_path not in PRODUCTION_LINE_LIMIT_BASELINE:
            raise AssertionError(
                f"{relative_path} has {line_count} lines; files over 1000 lines need an explicit governance baseline"
            )


def require_line_count_at_most(
    relative_path: str,
    limit: int,
    reason: str,
) -> None:
    line_count = len(read_text(relative_path).splitlines())
    if line_count > limit:
        raise AssertionError(
            f"{relative_path} has {line_count} lines; limit is {limit}: {reason}"
        )


def require_refactoring_file_growth_limits() -> None:
    for relative_path, (limit, reason) in REFACTORING_FILE_GROWTH_LIMITS.items():
        require_line_count_at_most(relative_path, limit, reason)


def require_program_run_request_builders_split() -> None:
    require_exact(
        "packages/konyak_cli/lib/src/domain/program/program_run_request_builders.dart",
        """export 'program_run_command_support.dart';
export 'program_run_linux_requests.dart';
export 'program_run_macos_requests.dart' hide macosWineEnvironmentForRequests;
export 'program_run_terminal_requests.dart';
""",
    )
    for relative_path in [
        "packages/konyak_cli/lib/src/domain/program/program_run_command_support.dart",
        "packages/konyak_cli/lib/src/domain/program/program_run_linux_requests.dart",
        "packages/konyak_cli/lib/src/domain/program/program_run_macos_requests.dart",
        "packages/konyak_cli/lib/src/domain/program/program_run_terminal_requests.dart",
    ]:
        if not (ROOT / relative_path).exists():
            raise AssertionError(f"{relative_path} must exist after splitting request builders")


def require_typed_program_run_request_boundary() -> None:
    relative_path = "packages/konyak_cli/lib/src/domain/program/program_run_models.dart"
    request_models = read_text(relative_path)
    expected_constructor_options = [
        ["required this.bottleId", "required BottleId bottleId,"],
        ["required this.programPath", "required ProgramPath programPath,"],
        ["required this.runnerKind", "required RunnerKind runnerKind,"],
        ["required this.executable", "required ProgramExecutable executable,"],
        ["required this.arguments", "required ProgramRunArguments arguments,"],
        ["required this.logPath", "required ProgramLogPath logPath,"],
        [
            "this.workingDirectory = const Option.none()",
            "Option<ProgramWorkingDirectoryPath> workingDirectory =",
        ],
        ["final BottleId bottleId", "required BottleId bottleId,"],
        ["final ProgramPath programPath", "required ProgramPath programPath,"],
        ["final RunnerKind runnerKind", "required RunnerKind runnerKind,"],
        [
            "final ProgramExecutable executable",
            "required ProgramExecutable executable,",
        ],
        [
            "final ProgramRunArguments arguments",
            "required ProgramRunArguments arguments,",
        ],
        ["final ProgramLogPath logPath", "required ProgramLogPath logPath,"],
        [
            "final Option<ProgramWorkingDirectoryPath> workingDirectory",
            "required Option<ProgramWorkingDirectoryPath> workingDirectory,",
        ],
    ]
    for expected_options in expected_constructor_options:
        if not any(expected in request_models for expected in expected_options):
            raise AssertionError(
                "ProgramRunRequest must expose a typed domain constructor term: "
                f"{expected_options[0]}"
            )

    start_match = re.search(r"\bclass\s+ProgramRunRequest\b", request_models)
    start = -1 if start_match is None else start_match.start()
    end = request_models.find("sealed class ProgramRunResult", start)
    if start == -1 or end == -1:
        raise AssertionError("ProgramRunRequest class section must be readable")
    constructor_section = request_models[start:end]
    forbidden_constructor_terms = [
        "required String bottleId",
        "required String programPath",
        "required String runnerKind",
        "required String executable",
        "required List<String> arguments",
        "required String logPath",
        "Option<String> workingDirectory",
    ]
    for forbidden in forbidden_constructor_terms:
        if forbidden in constructor_section:
            raise AssertionError(
                "ProgramRunRequest constructor must not expose primitive "
                f"domain-facing values: {forbidden}"
            )


def require_runner_kind_catalog_boundary() -> None:
    value_objects_path = (
        "packages/konyak_cli/lib/src/domain/shared/domain_value_objects.dart"
    )
    value_objects = read_text(value_objects_path)
    for expected in [
        "static const wine = RunnerKind._validated('wine');",
        "static const wineRegistry = RunnerKind._validated('wineRegistry');",
        "static const wineRegistryQuery = RunnerKind._validated('wineRegistryQuery');",
        "static const wineboot = RunnerKind._validated('wineboot');",
        "static const wineserver = RunnerKind._validated('wineserver');",
        "static const winedbg = RunnerKind._validated('winedbg');",
        "static const winetricks = RunnerKind._validated('winetricks');",
        "static const terminal = RunnerKind._validated('terminal');",
        "static const macosWine = RunnerKind._validated('macosWine');",
        "static const macosWineRegistry = RunnerKind._validated('macosWineRegistry');",
        "static const macosWineRegistryQuery = RunnerKind._validated(",
        "static const macosWineserver = RunnerKind._validated('macosWineserver');",
        "static const macosWinedbg = RunnerKind._validated('macosWinedbg');",
        "static const macosWinetricks = RunnerKind._validated('macosWinetricks');",
        "static const macosTerminal = RunnerKind._validated('macosTerminal');",
        "static const stableRequestKinds = <RunnerKind>[",
    ]:
        if expected not in value_objects:
            raise AssertionError(
                "RunnerKind must expose the stable request catalog: "
                f"{expected}"
            )

    require_contains(
        "packages/konyak_cli/test/runner_kind_catalog_test.dart",
        "stable runner-kind catalog preserves public request strings",
    )

    request_builder_paths = [
        "packages/konyak_cli/lib/src/domain/program/program_run_linux_requests.dart",
        "packages/konyak_cli/lib/src/domain/program/program_run_macos_requests.dart",
        "packages/konyak_cli/lib/src/domain/program/program_run_terminal_requests.dart",
        "packages/konyak_cli/lib/src/platform/linux/linux_program_run_requests.dart",
        "packages/konyak_cli/lib/src/platform/macos/macos_program_run_requests.dart",
        "packages/konyak_cli/lib/src/io/wine_run_requests.dart",
    ]
    direct_runner_kind_pattern = re.compile(r"RunnerKind\('[^']+'\)")
    for relative_path in request_builder_paths:
        source = read_text(relative_path)
        match = direct_runner_kind_pattern.search(source)
        if match is not None:
            raise AssertionError(
                "request builders must use the RunnerKind stable catalog "
                f"instead of direct literal construction: {relative_path} "
                f"{match.group(0)}"
            )


def require_runtime_platform_definition_type_fronts() -> None:
    models_path = (
        "packages/konyak_cli/lib/src/domain/runtime/runtime_validation_models.dart"
    )
    models = read_text(models_path)

    def class_section(class_name: str) -> str:
        match = re.search(
            rf"abstract class {class_name}\b[\s\S]*?(?=\n@Freezed|\nenum |\nabstract interface class|\Z)",
            models,
        )
        if match is None:
            raise AssertionError(f"{models_path} must contain {class_name}")
        return match.group(0)

    component_definition = class_section("RuntimeStackComponentDefinition")
    backend_definition = class_section("RuntimeBackendDefinition")
    platform_spec = class_section("RuntimePlatformSpec")

    for expected in [
        "required RuntimeComponentId id,",
        "required RuntimeName name,",
        "required RuntimeRole role,",
        "required List<RuntimeRelativePath> relativePaths,",
    ]:
        if expected not in component_definition:
            raise AssertionError(
                "RuntimeStackComponentDefinition must expose typed catalog "
                f"fields: {expected}"
            )

    for forbidden in [
        "required String id",
        "required String name",
        "required String role",
        "required List<List<String>> relativePaths",
    ]:
        if forbidden in component_definition:
            raise AssertionError(
                "RuntimeStackComponentDefinition must not expose primitive "
                f"catalog fields: {forbidden}"
            )

    for expected in [
        "required RuntimeBackendId id,",
        "required RuntimeName name,",
        "required RuntimeRole role,",
        "required List<RuntimeComponentId> componentIds,",
    ]:
        if expected not in backend_definition:
            raise AssertionError(
                "RuntimeBackendDefinition must expose typed catalog fields: "
                f"{expected}"
            )

    for forbidden in [
        "required String id",
        "required String name",
        "required String role",
        "required List<String> componentIds",
    ]:
        if forbidden in backend_definition:
            raise AssertionError(
                "RuntimeBackendDefinition must not expose primitive catalog "
                f"fields: {forbidden}"
            )

    for expected_pattern in [
        r"required\s+RuntimeId\s+runtimeId,",
        r"required\s+RuntimeName\s+runtimeName,",
        r"required\s+RuntimePlatformName\s+platform,",
        r"required\s+RuntimeArchitecture\s+architecture,",
        r"required\s+RunnerKind\s+runnerKind,",
        r"required\s+RuntimeStackId\s+stackId,",
        r"required\s+RuntimeStackName\s+stackName,",
        r"required\s+RuntimeRelativePath\s+requiredExecutableRelativePath,",
        r"required\s+RuntimeArchivePath\s+defaultArchiveFileName,",
        r"required\s+ProgramEnvironmentVariableName\s+developmentSourceManifestEnvironmentKey,",
        r"required\s+ProgramEnvironmentVariableName\s+releaseSourceManifestEnvironmentKey,",
        r"required\s+ProgramEnvironmentVariableName\s+developmentSourceSignatureEnvironmentKey,",
        r"required\s+ProgramEnvironmentVariableName\s+releaseSourceSignatureEnvironmentKey,",
        r"Option<RuntimeSourceManifestUrl>\s+defaultSourceManifestUrl,",
    ]:
        if re.search(expected_pattern, platform_spec) is None:
            raise AssertionError(
                "RuntimePlatformSpec must expose typed catalog fields matching: "
                f"{expected_pattern}"
            )

    for forbidden in [
        "required String runtimeId",
        "required String runtimeName",
        "required String platform",
        "required String architecture",
        "required String runnerKind",
        "required String stackId",
        "required String stackName",
        "required List<String> requiredExecutableRelativePath",
        "required String defaultArchiveFileName",
        "required String developmentSourceManifestEnvironmentKey",
        "required String releaseSourceManifestEnvironmentKey",
        "required String developmentSourceSignatureEnvironmentKey",
        "required String releaseSourceSignatureEnvironmentKey",
        "Option<String> defaultSourceManifestUrl",
    ]:
        if forbidden in platform_spec:
            raise AssertionError(
                "RuntimePlatformSpec must not expose primitive catalog fields: "
                f"{forbidden}"
            )

    require_contains(
        "packages/konyak_cli/test/runtime_platform_definition_type_fronts_test.dart",
        "platform catalog stores stable identities as value objects",
    )
    require_contains(
        "packages/konyak_cli/test/runtime_platform_definition_type_fronts_test.dart",
        "list-runtimes JSON preserves public schema strings",
    )

    support_path = (
        "packages/konyak_cli/lib/src/domain/runtime/runtime_platform_support.dart"
    )
    support = read_text(support_path)
    for expected in [
        "final linuxWineRuntimePlatformSpec = RuntimePlatformSpec(",
        "final macosKonyakRuntimePlatformSpec = RuntimePlatformSpec(",
        "runtimeId: RuntimeId(linuxWineRuntimeId),",
        "runtimeId: RuntimeId(macosWineRuntimeId),",
        "runnerKind: RunnerKind.wine,",
        "runnerKind: RunnerKind.macosWine,",
        "requiredExecutableRelativePath: RuntimeRelativePath(['bin', 'wine']),",
        "requiredExecutableRelativePath: RuntimeRelativePath(['bin', 'wineloader']),",
        "defaultArchiveFileName: RuntimeArchivePath('linux-wine.tar.xz'),",
        "defaultArchiveFileName: RuntimeArchivePath(macosWineArchiveFileName),",
        "ProgramEnvironmentVariableName(",
        "RuntimeSourceManifestUrl(macosWineRuntimeSourceManifestUrl)",
    ]:
        if expected not in support:
            raise AssertionError(
                "runtime platform support must construct typed platform "
                f"definitions: {expected}"
            )

    for forbidden in [
        "const linuxWineRuntimePlatformSpec = RuntimePlatformSpec(",
        "const macosKonyakRuntimePlatformSpec = RuntimePlatformSpec(",
        "runtimeId: linuxWineRuntimeId,",
        "runtimeId: macosWineRuntimeId,",
        "platform: 'linux',",
        "platform: 'macos',",
        "architecture: 'x86_64',",
        "runnerKind: 'wine',",
        "runnerKind: 'macosWine',",
        "stackId: 'linux-wine-runtime-stack',",
        "stackId: 'macos-konyak-runtime-stack',",
        "requiredExecutableRelativePath: <String>",
        "defaultArchiveFileName: '",
        "Option.of(macosWineRuntimeSourceManifestUrl)",
        "componentIds: <String>",
        "relativePaths: <List<String>>",
    ]:
        if forbidden in support:
            raise AssertionError(
                "runtime platform definitions must not pass primitive catalog "
                f"fronts directly: {forbidden}"
            )


def require_runtime_model_type_fronts() -> None:
    models_path = "packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart"
    models = read_text(models_path)

    def class_section(class_name: str) -> str:
        match = re.search(
            rf"abstract class {class_name}\b[\s\S]*?(?=\n@Freezed|\nabstract class |\nsealed class |\nenum |\Z)",
            models,
        )
        if match is None:
            raise AssertionError(f"{models_path} must contain {class_name}")
        return match.group(0)

    runtime_definition = class_section("RuntimeDefinition")
    runtime_record = class_section("RuntimeRecord")
    runtime_stack = class_section("RuntimeStack")
    runtime_stack_backend = class_section("RuntimeStackBackend")
    runtime_stack_component = class_section("RuntimeStackComponent")
    runtime_source_manifest = class_section("RuntimeSourceManifest")
    runtime_source_component = class_section("RuntimeSourceComponent")

    for expected in [
        "required RuntimeId id,",
        "required RuntimeName name,",
        "required RuntimePlatformName platform,",
        "required RuntimeArchitecture architecture,",
        "required RunnerKind runnerKind,",
        "Option<RuntimeDistributionKind> distributionKind",
        "Option<RuntimeArchiveUrl> archiveUrl",
        "Option<RuntimeVersionUrl> versionUrl",
    ]:
        if expected not in runtime_definition:
            raise AssertionError(
                "RuntimeDefinition must expose typed constructor fronts: "
                f"{expected}"
            )

    for forbidden in [
        "required String id",
        "required String name",
        "required String platform",
        "required String architecture",
        "required String runnerKind",
        "Option<String> distributionKind",
        "Option<String> archiveUrl",
        "Option<String> versionUrl",
    ]:
        if forbidden in runtime_definition:
            raise AssertionError(
                "RuntimeDefinition must not expose primitive constructor "
                f"fronts: {forbidden}"
            )

    for expected in [
        "required RuntimeId id,",
        "required RuntimeName name,",
        "required RuntimePlatformName platform,",
        "required RuntimeArchitecture architecture,",
        "required RunnerKind runnerKind,",
        "Option<RuntimeDistributionKind> distributionKind",
        "Option<RuntimeComponentPath> applicationSupportPath",
        "Option<RuntimeComponentPath> libraryPath",
        "Option<RuntimeComponentPath> executablePath",
        "Option<RuntimeArchiveUrl> archiveUrl",
        "Option<RuntimeVersionUrl> versionUrl",
    ]:
        if expected not in runtime_record:
            raise AssertionError(
                "RuntimeRecord must expose typed constructor fronts: "
                f"{expected}"
            )

    for forbidden in [
        "required String id",
        "required String name",
        "required String platform",
        "required String architecture",
        "required String runnerKind",
        "Option<String> distributionKind",
        "Option<String> applicationSupportPath",
        "Option<String> libraryPath",
        "Option<String> executablePath",
        "Option<String> archiveUrl",
        "Option<String> versionUrl",
    ]:
        if forbidden in runtime_record:
            raise AssertionError(
                "RuntimeRecord must not expose primitive constructor fronts: "
                f"{forbidden}"
            )

    for expected in [
        "required RuntimeStackId id,",
        "required RuntimeStackName name,",
        "required RuntimeCompatibilityTarget compatibilityTarget,",
    ]:
        if expected not in runtime_stack:
            raise AssertionError(
                "RuntimeStack must expose typed constructor fronts: "
                f"{expected}"
            )

    for forbidden in [
        "required String id",
        "required String name",
        "required String compatibilityTarget",
    ]:
        if forbidden in runtime_stack:
            raise AssertionError(
                "RuntimeStack must not expose primitive constructor fronts: "
                f"{forbidden}"
            )

    for expected in [
        "required RuntimeBackendId id,",
        "required RuntimeName name,",
        "required RuntimeRole role,",
        "required Iterable<RuntimeComponentId> componentIds,",
        "required Iterable<RuntimeComponentId> missingComponentIds,",
        "required Iterable<RuntimeMissingPath> missingPaths,",
    ]:
        if expected not in runtime_stack_backend:
            raise AssertionError(
                "RuntimeStackBackend must expose typed constructor fronts: "
                f"{expected}"
            )

    for forbidden in [
        "required String id",
        "required String name",
        "required String role",
        "required Iterable<String> componentIds",
        "required Iterable<String> missingComponentIds",
        "required Iterable<String> missingPaths",
    ]:
        if forbidden in runtime_stack_backend:
            raise AssertionError(
                "RuntimeStackBackend must not expose primitive constructor "
                f"fronts: {forbidden}"
            )

    for expected in [
        "required RuntimeComponentId id,",
        "required RuntimeName name,",
        "required RuntimeRole role,",
        "required Iterable<RuntimeComponentPath> paths,",
        "required Iterable<RuntimeMissingPath> missingPaths,",
        "Option<RuntimeVersion> version",
    ]:
        if expected not in runtime_stack_component:
            raise AssertionError(
                "RuntimeStackComponent must expose typed constructor fronts: "
                f"{expected}"
            )

    for forbidden in [
        "required String id",
        "required String name",
        "required String role",
        "required Iterable<String> paths",
        "required Iterable<String> missingPaths",
        "Option<String> version",
    ]:
        if forbidden in runtime_stack_component:
            raise AssertionError(
                "RuntimeStackComponent must not expose primitive constructor "
                f"fronts: {forbidden}"
            )

    for expected in [
        "required RuntimeId runtimeId,",
        "required RuntimeStackId stackId,",
        "componentById(RuntimeSourceComponentId id)",
    ]:
        if expected not in runtime_source_manifest:
            raise AssertionError(
                "RuntimeSourceManifest must expose typed fronts and lookup: "
                f"{expected}"
            )

    for forbidden in [
        "required String runtimeId",
        "required String stackId",
        "componentById(String id)",
    ]:
        if forbidden in runtime_source_manifest:
            raise AssertionError(
                "RuntimeSourceManifest must not expose primitive fronts or "
                f"lookup: {forbidden}"
            )

    for expected in [
        "required RuntimeSourceComponentId id,",
        "required RuntimeSourceComponentVersion version,",
        "required RuntimeArchiveUrl archiveUrl,",
        "required RuntimeArchiveChecksumValue sha256,",
    ]:
        if expected not in runtime_source_component:
            raise AssertionError(
                "RuntimeSourceComponent must expose typed constructor fronts: "
                f"{expected}"
            )

    for forbidden in [
        "required String id",
        "required String version",
        "required String archiveUrl",
        "required String sha256",
    ]:
        if forbidden in runtime_source_component:
            raise AssertionError(
                "RuntimeSourceComponent must not expose primitive constructor "
                f"fronts: {forbidden}"
            )

    records_path = "packages/konyak_cli/lib/src/io/runtime_platform_records.dart"
    records = read_text(records_path)
    for expected in [
        "id: platformSpec.runtimeId,",
        "name: platformSpec.runtimeName,",
        "platform: platformSpec.platform,",
        "architecture: platformSpec.architecture,",
        "runnerKind: platformSpec.runnerKind,",
        "distributionKind: Option.of(",
        "RuntimeDistributionKind(",
        "versionUrl: versionUrl.map(RuntimeVersionUrl.new),",
        "id: platformSpec.stackId,",
        "name: platformSpec.stackName,",
        "compatibilityTarget: RuntimeCompatibilityTarget(platformSpec.stackId.value),",
        "id: definition.id,",
        "role: definition.role,",
        "componentIds: definition.componentIds,",
        "paths: paths.map(RuntimeComponentPath.new),",
        "missingPaths: missingPaths.map(RuntimeMissingPath.new),",
    ]:
        if expected not in records:
            raise AssertionError(
                "runtime platform records must construct runtime models with "
                f"typed fronts: {expected}"
            )

    for forbidden in [
        "id: platformSpec.runtimeId.value",
        "name: platformSpec.runtimeName.value",
        "platform: platformSpec.platform.value",
        "architecture: platformSpec.architecture.value",
        "runnerKind: platformSpec.runnerKind.value",
        "id: platformSpec.stackId.value",
        "name: platformSpec.stackName.value",
        "id: definition.id.value",
        "name: definition.name.value",
        "role: definition.role.value",
        "componentIds: definition.componentIds.map((id) => id.value)",
        "missingPaths.addAll(component.missingPaths.map((path) => path.value))",
        "paths: paths,",
    ]:
        if forbidden in records:
            raise AssertionError(
                "runtime platform records must not unwrap typed values before "
                f"runtime model construction: {forbidden}"
            )

    manifest_support_path = (
        "packages/konyak_cli/lib/src/io/runtime_source_manifest_support.dart"
    )
    manifest_support = read_text(manifest_support_path)
    for expected in [
        "runtimeId: RuntimeId(runtimeId),",
        "stackId: RuntimeStackId(stackId),",
        "id: RuntimeSourceComponentId(id),",
        "version: RuntimeSourceComponentVersion(version),",
        "archiveUrl: RuntimeArchiveUrl(archiveUrl),",
        "sha256: RuntimeArchiveChecksumValue(sha256),",
    ]:
        if expected not in manifest_support:
            raise AssertionError(
                "runtime source manifest parsing must validate primitive "
                f"schema values into typed domain state: {expected}"
            )

    for forbidden in [
        "runtimeId: runtimeId,",
        "stackId: stackId,",
        "id: id,",
        "version: version,",
        "archiveUrl: archiveUrl,",
        "sha256: sha256,",
    ]:
        if forbidden in manifest_support:
            raise AssertionError(
                "runtime source manifest parsing must not pass primitive "
                f"schema values into domain models: {forbidden}"
            )

    archive_planning_path = (
        "packages/konyak_cli/lib/src/domain/runtime/runtime_source_archive_planning.dart"
    )
    require_contains(
        archive_planning_path,
        "manifest.componentById(\n    RuntimeSourceComponentId('wine'),\n  )",
    )

    require_contains(
        "packages/konyak_cli/test/runtime_model_type_fronts_test.dart",
        "runtime definition constructor accepts typed domain values",
    )
    require_contains(
        "packages/konyak_cli/test/runtime_model_type_fronts_test.dart",
        "source manifest parser remains the primitive adapter boundary",
    )
    helpers_path = "packages/konyak_cli/test/support/cli_contract_full_helpers.dart"
    for expected in [
        "RuntimeDefinition runtimeDefinitionFixture({",
        "RuntimeRecord runtimeRecordFixture({",
        "RuntimeStack runtimeStackFixture({",
        "RuntimeStackBackend runtimeStackBackendFixture({",
        "RuntimeStackComponent runtimeStackComponentFixture({",
    ]:
        require_contains(helpers_path, expected)


def require_typed_program_run_planner_boundary() -> None:
    planner_path = "packages/konyak_cli/lib/src/domain/program/program_runner.dart"
    planner = read_text(planner_path)
    expected_terms = [
        "required ProgramPath programPath",
        "wineArgumentsForProgramPath(programPath)",
    ]
    for expected in expected_terms:
        if expected not in planner:
            raise AssertionError(
                "ProgramRunPlanner.plan must expose a typed program path boundary: "
                f"{expected}"
            )

    forbidden_terms = [
        "required String programPath",
        "wineArgumentsForProgramPath(programPath.value)",
    ]
    for forbidden in forbidden_terms:
        if forbidden in planner:
            raise AssertionError(
                "ProgramRunPlanner.plan must not expose primitive program path "
                f"values: {forbidden}"
            )

    argument_support_path = (
        "packages/konyak_cli/lib/src/domain/program/program_argument_support.dart"
    )
    argument_support = read_text(argument_support_path)
    expected_support_terms = [
        "Option<ProgramRunArguments> wineArgumentsForProgramPath(",
        "ProgramPath programPath,",
        "ProgramRunArguments(<String>[programPath.value])",
    ]
    for expected in expected_support_terms:
        if expected not in argument_support:
            raise AssertionError(
                "program argument support must expose typed Wine arguments: "
                f"{expected}"
            )

    forbidden_support_terms = [
        "Option<List<String>> wineArgumentsForProgramPath(String programPath)",
        "bool isSupportedProgramPath(String programPath)",
    ]
    for forbidden in forbidden_support_terms:
        if forbidden in argument_support:
            raise AssertionError(
                "program argument support must not expose primitive "
                f"program-path APIs: {forbidden}"
            )


def require_typed_bottle_command_planner_boundary() -> None:
    planner_path = "packages/konyak_cli/lib/src/domain/program/program_runner.dart"
    planner = read_text(planner_path)
    expected_terms = [
        "required BottleCommand command",
        "required SupportedBottleCommand supportedCommand",
        "supportedBottleCommand(command)",
        "final command = supportedCommand.command;",
        "switch (supportedCommand.planKind)",
        "initialWineCommand: Option.of(command)",
    ]
    for expected in expected_terms:
        if expected not in planner:
            raise AssertionError(
                "ProgramRunPlanner.planBottleCommand must expose a typed "
                f"bottle command boundary: {expected}"
            )

    forbidden_terms = [
        "required String command",
        "required String supportedCommand",
        "Option.of(supportedCommand.value)",
        "supportedCommand.value == 'terminal'",
        "supportedCommand.value == 'cmd'",
        "supportedCommand.value == 'simulate-reboot'",
        "supportedCommand.value == 'winetricks'",
    ]
    for forbidden in forbidden_terms:
        if forbidden in planner:
            raise AssertionError(
                "ProgramRunPlanner.planBottleCommand must not expose primitive "
                f"command values: {forbidden}"
            )

    argument_support_path = (
        "packages/konyak_cli/lib/src/domain/program/program_argument_support.dart"
    )
    argument_support = read_text(argument_support_path)
    expected_support_terms = [
        "ProgramRunArguments wineArgumentsForBottleCommand(BottleCommand command)",
        "ProgramRunArguments programSettingsArguments(ProgramSettingsRecord settings)",
        "ProgramLogPath programSettingsLogPath({",
        "ProgramRunArguments registryUpdateArguments(RegistryValueUpdate update)",
        "ProgramRunArguments registryQueryArguments(RegistryValueQuery query)",
        "enum BottleCommandPlanKind",
        "typedef SupportedBottleCommand = ({",
        "Option<SupportedBottleCommand> supportedBottleCommand(BottleCommand command)",
        "final normalized = command.value.trim().toLowerCase();",
        "_supportedBottleCommand(BottleCommand(normalized))",
        "planKind: _bottleCommandPlanKind(command)",
    ]
    for expected in expected_support_terms:
        search_source = (
            read_text("packages/konyak_cli/lib/src/domain/program/program_registry_plans.dart")
            if expected.startswith("ProgramRunArguments registry")
            else argument_support
        )
        if expected not in search_source:
            raise AssertionError(
                "program argument support must expose typed bottle command "
                f"helpers: {expected}"
            )
    registry_plans_source = read_text(
        "packages/konyak_cli/lib/src/domain/program/program_registry_plans.dart"
    )
    for expected in [
        "update.key.value",
        "update.name.value",
        "update.type.value",
        "update.data.value",
        "query.key.value",
        "query.name.value",
    ]:
        if expected not in registry_plans_source:
            raise AssertionError(
                "registry argument helpers must project typed values to argv: "
                f"{expected}"
            )

    forbidden_support_terms = [
        "List<String> programSettingsArguments(ProgramSettingsRecord settings)",
        "String programSettingsLogPath({",
        "List<String> registryUpdateArguments(RegistryValueUpdate update)",
        "List<String> registryQueryArguments(RegistryValueQuery query)",
        "List<String> wineArgumentsForBottleCommand(String command)",
        "List<String> wineArgumentsForBottleCommand(BottleCommand command)",
        "Option<String> supportedBottleCommand(String command)",
    ]
    for forbidden in forbidden_support_terms:
        search_sources = [
            argument_support,
            read_text("packages/konyak_cli/lib/src/domain/program/program_registry_plans.dart"),
        ]
        if any(forbidden in source for source in search_sources):
            raise AssertionError(
                "program argument support must not expose primitive bottle "
                f"command helpers: {forbidden}"
            )

    terminal_boundary_paths = [
        "packages/konyak_cli/lib/src/domain/program/program_run_terminal_requests.dart",
        "packages/konyak_cli/lib/src/platform/platform_terminal_commands.dart",
        "packages/konyak_cli/lib/src/io/wine_run_requests.dart",
    ]
    for path in terminal_boundary_paths:
        contents = read_text(path)
        if "Option<BottleCommand> initialWineCommand" not in contents:
            raise AssertionError(
                f"{path} must keep terminal initial Wine commands typed"
            )
        for forbidden in ["Option<String> initialWineCommand"]:
            if forbidden in contents:
                raise AssertionError(
                    f"{path} must not expose primitive terminal command "
                    f"arguments: {forbidden}"
                )

    terminal_helper_paths = [
        "packages/konyak_cli/lib/src/domain/program/program_run_terminal_requests.dart",
        "packages/konyak_cli/lib/src/platform/platform_terminal_commands.dart",
    ]
    for path in terminal_helper_paths:
        contents = read_text(path)
        if "required BottleCommand command" not in contents:
            raise AssertionError(
                f"{path} must keep terminal initial command helpers typed"
            )
        if "required String command" in contents:
            raise AssertionError(
                f"{path} must not expose primitive terminal initial command "
                "helper arguments"
            )


def require_typed_winetricks_verb_planner_boundary() -> None:
    planner_path = "packages/konyak_cli/lib/src/domain/program/program_runner.dart"
    planner = read_text(planner_path)
    expected_terms = [
        "required WinetricksVerbId verb",
        "isSupportedWinetricksVerb(verb)",
        "verb: Option.of(verb)",
    ]
    for expected in expected_terms:
        if expected not in planner:
            raise AssertionError(
                "ProgramRunPlanner.planWinetricksVerb must expose a typed "
                f"Winetricks verb boundary: {expected}"
            )

    forbidden_terms = [
        "required String verb",
        "isSupportedWinetricksVerb(verb.value)",
        "verb: Option.of(verb.value)",
    ]
    for forbidden in forbidden_terms:
        if forbidden in planner:
            raise AssertionError(
                "ProgramRunPlanner.planWinetricksVerb must not expose "
                f"primitive verb values: {forbidden}"
            )

    command_support_path = (
        "packages/konyak_cli/lib/src/domain/program/program_run_command_support.dart"
    )
    command_support = read_text(command_support_path)
    expected_support_terms = [
        "bool isSupportedWinetricksVerb(WinetricksVerbId verb)",
        "hasMatch(verb.value)",
    ]
    for expected in expected_support_terms:
        if expected not in command_support:
            raise AssertionError(
                "program command support must expose typed Winetricks verb "
                f"helpers: {expected}"
            )

    if "bool isSupportedWinetricksVerb(String verb)" in command_support:
        raise AssertionError(
            "program command support must not expose primitive Winetricks "
            "verb helpers"
        )

    linux_requests_path = (
        "packages/konyak_cli/lib/src/domain/program/program_run_linux_requests.dart"
    )
    macos_requests_path = (
        "packages/konyak_cli/lib/src/domain/program/program_run_macos_requests.dart"
    )
    request_builders = {
        linux_requests_path: read_text(linux_requests_path),
        macos_requests_path: read_text(macos_requests_path),
    }
    for path, contents in request_builders.items():
        expected_request_terms = [
            "Option<WinetricksVerbId> verb",
            "verb.match(() => 'winetricks', (value) => value.value)",
            "verb.match(() => const <String>[], (value) => <String>[value.value])",
        ]
        for expected in expected_request_terms:
            if expected not in contents:
                raise AssertionError(
                    f"{path} must expose typed Winetricks request builders: "
                    f"{expected}"
                )

        if "Option<String> verb" in contents:
            raise AssertionError(
                f"{path} must not expose primitive Winetricks verb options"
            )


def require_typed_wine_process_planner_boundary() -> None:
    planner_path = "packages/konyak_cli/lib/src/domain/program/program_runner.dart"
    planner = read_text(planner_path)
    expected_terms = [
        "required WineProcessId processId",
        "final winedbgCommand = winedbgProcessKillPlan(processId);",
        "winedbgCommand: winedbgCommand,",
    ]
    for expected in expected_terms:
        if expected not in planner:
            raise AssertionError(
                "ProgramRunPlanner.planWineProcessKill must expose a typed "
                f"Wine process-id boundary: {expected}"
            )

    forbidden_terms = [
        "required String processId",
        "winedbgAttachProcessId(processId.value)",
    ]
    for forbidden in forbidden_terms:
        if forbidden in planner:
            raise AssertionError(
                "ProgramRunPlanner.planWineProcessKill must not expose "
                f"primitive process-id values: {forbidden}"
            )

    command_support_path = (
        "packages/konyak_cli/lib/src/domain/program/program_run_command_support.dart"
    )
    command_support = read_text(command_support_path)
    expected_support_terms = [
        "String winedbgAttachProcessId(WineProcessId processId)",
        "final normalized = processId.value.trim();",
        "WinedbgCommandPlan winedbgProcessListPlan()",
        "WinedbgCommandPlan winedbgProcessKillPlan(WineProcessId processId)",
        "winedbgAttachProcessId(processId)",
    ]
    for expected in expected_support_terms:
        if expected not in command_support:
            raise AssertionError(
                "program command support must expose typed Wine process-id "
                f"helpers: {expected}"
            )

    if "String winedbgAttachProcessId(String processId)" in command_support:
        raise AssertionError(
            "program command support must not expose primitive Wine process-id "
            "helpers"
        )

    request_builder_paths = [
        "packages/konyak_cli/lib/src/domain/program/program_run_linux_requests.dart",
        "packages/konyak_cli/lib/src/domain/program/program_run_macos_requests.dart",
        "packages/konyak_cli/lib/src/platform/linux/linux_program_run_requests.dart",
        "packages/konyak_cli/lib/src/platform/macos/macos_program_run_requests.dart",
    ]
    for path in request_builder_paths:
        contents = read_text(path)
        request_match = re.search(
            r"ProgramRunRequest\s+(?:linux|macos)WinedbgRequest\(\{"
            r"(?P<body>.*?)\n\}",
            contents,
            re.S,
        )
        if request_match is None:
            raise AssertionError(f"{path} must define a winedbg request builder")

        request_body = request_match.group("body")
        if "required WinedbgCommandPlan winedbgCommand" not in request_body:
            raise AssertionError(
                f"{path} must accept typed winedbg command plans"
            )
        forbidden_winedbg_terms = [
            "required String command",
            "required String logName",
            "List<String> trailingArguments",
        ]
        for forbidden in forbidden_winedbg_terms:
            if forbidden in request_body:
                raise AssertionError(
                    f"{path} must not expose primitive winedbg request "
                    f"arguments: {forbidden}"
                )

    process_results_path = (
        "packages/konyak_cli/lib/src/cli/cli_app_process_results.dart"
    )
    process_results = read_text(process_results_path)
    expected_process_result_terms = [
        "required WineProcessId processId",
        "processId: processId,",
        "processId: Option.of(processId)",
    ]
    for expected in expected_process_result_terms:
        if expected not in process_results:
            raise AssertionError(
                "CLI process result orchestration must preserve typed Wine "
                f"process ids until JSON projection: {expected}"
            )

    wine_process_handler_path = (
        "packages/konyak_cli/lib/src/cli/cli_wine_process_handlers.dart"
    )
    wine_process_handler = read_text(wine_process_handler_path)
    if (
        "processId: wineProcessTerminationRequest.processId.value"
        in wine_process_handler
    ):
        raise AssertionError(
            "Wine process CLI handler must not unwrap process ids before "
            "result orchestration"
        )


def require_typed_detached_process_starter_boundary() -> None:
    domain_path = "packages/konyak_cli/lib/src/domain/program/program_run_models.dart"
    domain = read_text(domain_path)
    expected_domain_terms = [
        "abstract interface class DetachedProcessStarter",
        "required ProgramExecutable executable",
        "required ProgramRunArguments arguments",
    ]
    for expected in expected_domain_terms:
        if expected not in domain:
            raise AssertionError(
                "DetachedProcessStarter must expose typed startup requests: "
                f"{expected}"
            )

    forbidden_domain_terms = [
        "required String executable",
        "required List<String> arguments",
    ]
    detached_match = re.search(
        r"abstract interface class DetachedProcessStarter\b(?P<body>.*?)(?=\n\})",
        domain,
        re.S,
    )
    if detached_match is None:
        raise AssertionError("DetachedProcessStarter interface is missing")
    detached_body = detached_match.group("body")
    for forbidden in forbidden_domain_terms:
        if forbidden in detached_body:
            raise AssertionError(
                "DetachedProcessStarter must not expose primitive startup "
                f"request fields: {forbidden}"
            )

    app_update_handoff_path = (
        "packages/konyak_cli/lib/src/io/app_update_handoff_installers.dart"
    )
    app_update_handoff = read_text(app_update_handoff_path)
    expected_handoff_terms = [
        "executable: ProgramExecutable('bash')",
        "arguments: ProgramRunArguments(<String>[",
    ]
    for expected in expected_handoff_terms:
        if expected not in app_update_handoff:
            raise AssertionError(
                "app update handoff must build typed detached process startup "
                f"requests: {expected}"
            )


def require_typed_path_opener_boundary() -> None:
    domain_path = "packages/konyak_cli/lib/src/domain/program/program_runner.dart"
    domain = read_text(domain_path)
    expected_domain_terms = [
        "abstract interface class PathOpener",
        "PathOpenResult openPath(PathOpenTarget target)",
        "PathOpenResult revealPath(PathRevealTarget target)",
    ]
    for expected in expected_domain_terms:
        if expected not in domain:
            raise AssertionError(
                "PathOpener must expose typed open/reveal targets: "
                f"{expected}"
            )

    path_opener_match = re.search(
        r"abstract interface class PathOpener\b(?P<body>.*?)(?=\n\})",
        domain,
        re.S,
    )
    if path_opener_match is None:
        raise AssertionError("PathOpener interface is missing")
    path_opener_body = path_opener_match.group("body")
    forbidden_domain_terms = [
        "openPath(String",
        "revealPath(String",
    ]
    for forbidden in forbidden_domain_terms:
        if forbidden in path_opener_body:
            raise AssertionError(
                "PathOpener must not expose primitive open/reveal targets: "
                f"{forbidden}"
            )

    expected_terms_by_path = {
        "packages/konyak_cli/lib/src/io/app_update_installer.dart": [
            "pathOpener.openPath(PathOpenTarget(archivePath))",
        ],
        "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart": [
            "pathOpener.openPath(PathOpenTarget(openUrl))",
        ],
        "packages/konyak_cli/lib/src/cli/cli_location_winetricks_handlers.dart": [
            "opener.openPath(PathOpenTarget(path))",
            "opener.revealPath(PathRevealTarget(path))",
        ],
    }
    for path, expected_terms in expected_terms_by_path.items():
        source = read_text(path)
        for expected in expected_terms:
            if expected not in source:
                raise AssertionError(
                    "Path opener call sites must build typed open/reveal "
                    f"targets: {expected}"
                )


def require_typed_runtime_executable_probe_boundary() -> None:
    domain_path = (
        "packages/konyak_cli/lib/src/domain/runtime/runtime_validation_models.dart"
    )
    domain = read_text(domain_path)
    expected_domain_terms = [
        "abstract interface class RuntimeExecutableProbe",
        "required ProgramExecutable executable",
        "required ProgramRunArguments arguments",
        "required ProgramWorkingDirectoryPath workingDirectory",
    ]
    for expected in expected_domain_terms:
        if expected not in domain:
            raise AssertionError(
                "RuntimeExecutableProbe must expose typed executable "
                f"requests: {expected}"
            )

    probe_match = re.search(
        r"abstract interface class RuntimeExecutableProbe\b(?P<body>.*?)(?=\n\})",
        domain,
        re.S,
    )
    if probe_match is None:
        raise AssertionError("RuntimeExecutableProbe interface is missing")
    probe_body = probe_match.group("body")
    forbidden_domain_terms = [
        "required String executable",
        "required List<String> arguments",
        "required String workingDirectory",
    ]
    for forbidden in forbidden_domain_terms:
        if forbidden in probe_body:
            raise AssertionError(
                "RuntimeExecutableProbe must not expose primitive process "
                f"request fields: {forbidden}"
            )

    runtime_validator_path = (
        "packages/konyak_cli/lib/src/platform/macos/macos_runtime_validator.dart"
    )
    runtime_validator = read_text(runtime_validator_path)
    expected_validator_terms = [
        "executable: ProgramExecutable(executablePath)",
        "arguments: ProgramRunArguments(const <String>['--version'])",
        "workingDirectory: ProgramWorkingDirectoryPath(dirname(executablePath))",
    ]
    for expected in expected_validator_terms:
        if expected not in runtime_validator:
            raise AssertionError(
                "Runtime validator must build typed executable probe "
                f"requests: {expected}"
            )

    probe_io_path = "packages/konyak_cli/lib/src/io/runtime_executable_probe.dart"
    probe_io = read_text(probe_io_path)
    expected_io_terms = [
        "executable.value",
        "arguments.value",
        "workingDirectory.value",
    ]
    for expected in expected_io_terms:
        if expected not in probe_io:
            raise AssertionError(
                "Runtime executable probe I/O must unwrap typed requests only "
                f"at the process boundary: {expected}"
            )


def require_typed_winetricks_verb_lister_boundary() -> None:
    repository_path = "packages/konyak_cli/lib/src/repository/repository_interfaces.dart"
    repository = read_text(repository_path)
    expected_repository_terms = [
        "abstract interface class WinetricksVerbLister",
        "WinetricksVerbListResult listVerbs({required ProgramExecutable executable})",
    ]
    for expected in expected_repository_terms:
        if expected not in repository:
            raise AssertionError(
                "WinetricksVerbLister must expose a typed executable request: "
                f"{expected}"
            )

    lister_match = re.search(
        r"abstract interface class WinetricksVerbLister\b(?P<body>.*?)(?=\n\})",
        repository,
        re.S,
    )
    if lister_match is None:
        raise AssertionError("WinetricksVerbLister interface is missing")
    if "required String executable" in lister_match.group("body"):
        raise AssertionError(
            "WinetricksVerbLister must not expose primitive executable "
            "requests"
        )

    winetricks_io_path = "packages/konyak_cli/lib/src/io/winetricks_io.dart"
    winetricks_io = read_text(winetricks_io_path)
    expected_io_terms = [
        "lister.listVerbs(executable: ProgramExecutable(managedExecutable))",
        "required ProgramExecutable executable",
        "executable.value",
    ]
    for expected in expected_io_terms:
        if expected not in winetricks_io:
            raise AssertionError(
                "Winetricks lister I/O must keep executable requests typed "
                f"until the process boundary: {expected}"
            )


def require_typed_runtime_id_service_boundaries() -> None:
    update_path = "packages/konyak_cli/lib/src/domain/update/update_records.dart"
    update = read_text(update_path)
    expected_update_terms = [
        "factory RuntimeUpdateCheckResult.runtimeNotFound(RuntimeId runtimeId)",
        "RuntimeUpdateCheckResult check(RuntimeId runtimeId)",
        "RuntimeReleaseMetadataFetchResult fetch(RuntimeVersionUrl versionUrl)",
    ]
    for expected in expected_update_terms:
        if expected not in update:
            raise AssertionError(
                "Runtime update service boundaries must use RuntimeId: "
                f"{expected}"
            )

    update_checker_match = re.search(
        r"abstract interface class RuntimeUpdateChecker\b(?P<body>.*?)(?=\n\})",
        update,
        re.S,
    )
    if update_checker_match is None:
        raise AssertionError("RuntimeUpdateChecker interface is missing")
    if "check(String runtimeId)" in update_checker_match.group("body"):
        raise AssertionError(
            "RuntimeUpdateChecker must not expose primitive runtime ids"
        )

    metadata_fetcher_match = re.search(
        r"abstract interface class RuntimeReleaseMetadataFetcher\b"
        r"(?P<body>.*?)(?=\n\})",
        update,
        re.S,
    )
    if metadata_fetcher_match is None:
        raise AssertionError("RuntimeReleaseMetadataFetcher interface is missing")
    if "fetch(String versionUrl)" in metadata_fetcher_match.group("body"):
        raise AssertionError(
            "RuntimeReleaseMetadataFetcher must not expose primitive version urls"
        )

    validation_path = (
        "packages/konyak_cli/lib/src/domain/runtime/runtime_validation_models.dart"
    )
    validation = read_text(validation_path)
    expected_validation_terms = [
        "factory RuntimeValidationResult.runtimeNotFound(RuntimeId runtimeId)",
        "RuntimeValidationResult validate(RuntimeId runtimeId)",
    ]
    for expected in expected_validation_terms:
        if expected not in validation:
            raise AssertionError(
                "Runtime validation service boundaries must use RuntimeId: "
                f"{expected}"
            )

    validator_match = re.search(
        r"abstract interface class RuntimeValidator\b(?P<body>.*?)(?=\n\})",
        validation,
        re.S,
    )
    if validator_match is None:
        raise AssertionError("RuntimeValidator interface is missing")
    if "validate(String runtimeId)" in validator_match.group("body"):
        raise AssertionError("RuntimeValidator must not expose primitive runtime ids")

    validation_support_path = (
        "packages/konyak_cli/lib/src/domain/runtime/runtime_validation_support.dart"
    )
    validation_support = read_text(validation_support_path)
    expected_validation_support_terms = [
        "Option<RuntimeVersion> versionFor({",
        "required RuntimeRootPath runtimeRoot,",
        "required RuntimeComponentId componentId,",
    ]
    for expected in expected_validation_support_terms:
        if expected not in validation_support:
            raise AssertionError(
                "Runtime validation support must keep stack version probes "
                f"typed: {expected}"
            )

    forbidden_validation_support_terms = [
        "Option<String> versionFor({",
        "required String runtimeRoot",
        "required String componentId",
    ]
    for forbidden in forbidden_validation_support_terms:
        if forbidden in validation_support:
            raise AssertionError(
                "Runtime validation support must not expose primitive stack "
                f"version probes: {forbidden}"
            )

    runtime_handlers_path = (
        "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart"
    )
    runtime_handlers = read_text(runtime_handlers_path)
    expected_handler_terms = [
        "runtimeId: RuntimeId(runtimeUpdateId)",
        "runtimeId: RuntimeId(runtimeUpdateInstallId)",
        "runtimeId: RuntimeId(runtimeValidationId)",
        "required RuntimeId runtimeId",
    ]
    for expected in expected_handler_terms:
        if expected not in runtime_handlers:
            raise AssertionError(
                "Runtime CLI handlers must convert parsed ids once at the "
                f"boundary: {expected}"
            )

    update_results_path = (
        "packages/konyak_cli/lib/src/cli/cli_update_runtime_results.dart"
    )
    update_results = read_text(update_results_path)
    expected_update_result_terms = [
        "required RuntimeId runtimeId",
        "checker.check(runtimeId)",
        "switch (runtimeId.value)",
    ]
    for expected in expected_update_result_terms:
        if expected not in update_results:
            raise AssertionError(
                "Runtime update install results must preserve RuntimeId until "
                f"JSON or dispatch boundaries: {expected}"
            )

    update_checker_io_path = "packages/konyak_cli/lib/src/io/runtime_update_checker_io.dart"
    update_checker_io = read_text(update_checker_io_path)
    expected_update_checker_io_terms = [
        "RuntimeUpdateCheckResult check(RuntimeId runtimeId)",
        "runtimeById(runtimeCatalog.listRuntimes(), runtimeId)",
        "versionUrl: versionUrl,",
        "releaseMetadataFetcher.fetch(versionUrl)",
    ]
    for expected in expected_update_checker_io_terms:
        if expected not in update_checker_io:
            raise AssertionError(
                "Runtime update checker I/O must preserve typed runtime "
                "update values until JSON or process boundaries: "
                f"catalog lookup: {expected}"
            )

    update_support_path = (
        "packages/konyak_cli/lib/src/domain/runtime/runtime_update_support.dart"
    )
    update_support = read_text(update_support_path)
    expected_update_support_terms = [
        "RuntimeId runtimeId,",
        "firstWhereOption(runtimes, (runtime) => runtime.id == runtimeId)",
        "UpdateCheckStatus updateStatus({",
        "required Option<StringDomainValueObject> currentVersion,",
        "required StringDomainValueObject latestVersion,",
    ]
    for expected in expected_update_support_terms:
        if expected not in update_support:
            raise AssertionError(
                "Runtime update support must preserve typed runtime ids and "
                f"version values: {expected}"
            )

    forbidden_update_support_terms = [
        "String runtimeId,",
        "String updateStatus({",
        "required Option<String> currentVersion",
        "required String latestVersion",
    ]
    for forbidden in forbidden_update_support_terms:
        if forbidden in update_support:
            raise AssertionError(
                "Runtime update support must not expose primitive runtime "
                f"update values: {forbidden}"
            )

    runtime_update_checker_path = (
        "packages/konyak_cli/lib/src/domain/runtime/runtime_update_checker.dart"
    )
    runtime_update_checker = read_text(runtime_update_checker_path)
    expected_runtime_update_terms = [
        "required RuntimeVersionUrl versionUrl,",
        "versionUrl: Option.of(versionUrl),",
        "status: updateStatus(",
    ]
    for expected in expected_runtime_update_terms:
        if expected not in runtime_update_checker:
            raise AssertionError(
                "Runtime update checker domain helpers must preserve typed "
                f"version URLs and status values: {expected}"
            )

    if "required String versionUrl" in runtime_update_checker:
        raise AssertionError(
            "Runtime update checker domain helpers must not expose primitive "
            "version URLs"
        )

    app_update_checker_path = "packages/konyak_cli/lib/src/io/app_update_checker_io.dart"
    app_update_checker = read_text(app_update_checker_path)
    if "releaseMetadataFetcher.fetch(versionUrl)" not in app_update_checker:
        raise AssertionError(
            "App update checker must pass typed RuntimeVersionUrl to release "
            "metadata fetcher"
        )

    release_fetcher_path = "packages/konyak_cli/lib/src/io/release_metadata_fetcher.dart"
    release_fetcher = read_text(release_fetcher_path)
    expected_release_fetcher_terms = [
        "RuntimeReleaseMetadataFetchResult fetch(RuntimeVersionUrl versionUrl)",
        "versionUrl.value",
    ]
    for expected in expected_release_fetcher_terms:
        if expected not in release_fetcher:
            raise AssertionError(
                "Release metadata fetcher I/O must unwrap RuntimeVersionUrl "
                f"only at the curl boundary: {expected}"
            )


def require_typed_bottle_repository_id_boundary() -> None:
    interface_path = "packages/konyak_cli/lib/src/repository/repository_interfaces.dart"
    interface = read_text(interface_path)
    expected_interface_terms = [
        "IoResult<Option<BottleRecord>> findBottle(BottleId id);",
        "BottleDeleteResult deleteBottle(BottleId id);",
    ]
    for expected in expected_interface_terms:
        if expected not in interface:
            raise AssertionError(
                "Bottle repository boundaries must use BottleId: "
                f"{expected}"
            )

    forbidden_interface_terms = [
        "IoResult<Option<BottleRecord>> findBottle(String id);",
        "BottleDeleteResult deleteBottle(String id);",
        "IoResult<BottleRecord?> findBottle",
    ]
    for forbidden in forbidden_interface_terms:
        if forbidden in interface:
            raise AssertionError(
                "Bottle repository boundaries must not expose primitive or "
                f"nullable bottle lookups: {forbidden}"
            )

    expected_parser_terms = {
        "packages/konyak_cli/lib/src/cli/cli_value_object_parsers.dart": [
            "BottleId? requiredCliBottleId",
            "Option<BottleId> requiredCliBottleIdOption(",
            "return nullableParsedOption(requiredCliBottleIdOption(results, index: index));",
            "return requiredCliRestOption(results, index: index).map(BottleId.new);",
        ],
        "packages/konyak_cli/lib/src/cli/cli_bottle_parsers.dart": [
            "BottleId? parseJsonBottleInspectCommand",
            "BottleId? parseJsonBottleProgramsListCommand",
            "BottleId? parseJsonBottleDeleteCommand",
            "Option<BottleId> parseJsonBottleInspectCommandOption",
            "Option<BottleId> parseJsonBottleProgramsListCommandOption",
            "Option<BottleId> parseJsonBottleDeleteCommandOption",
            "return $(requiredCliBottleIdOption(results));",
        ],
        "packages/konyak_cli/lib/src/cli/cli_program_run_parsers.dart": [
            "final BottleId bottleId;",
            "final bottleId = $(requiredCliBottleIdOption(results));",
        ],
        "packages/konyak_cli/lib/src/cli/cli_location_parsers.dart": [
            "final BottleId bottleId;",
            "final bottleId = $(requiredCliBottleIdOption(results));",
        ],
    }
    for path, expected_terms in expected_parser_terms.items():
        source = read_text(path)
        for expected in expected_terms:
            if expected not in source:
                raise AssertionError(
                    "CLI bottle-id parsers must preserve BottleId before "
                    f"repository calls: {expected}"
                )

    expected_repository_terms = {
        "packages/konyak_cli/lib/src/repository/file_bottle_repository.dart": [
            "IoResult<Option<BottleRecord>> findBottle(BottleId id)",
            "BottleDeleteResult deleteBottle(BottleId id)",
        ],
        "packages/konyak_cli/lib/src/repository/memory_bottle_repository.dart": [
            "IoResult<Option<BottleRecord>> findBottle(BottleId id)",
            "BottleDeleteResult deleteBottle(BottleId id)",
            "mapValue(bottlesById, id.value)",
        ],
        "packages/konyak_cli/lib/src/repository/composite_bottle_repository.dart": [
            "IoResult<Option<BottleRecord>> findBottle(BottleId id)",
            "BottleDeleteResult deleteBottle(BottleId id)",
        ],
        "packages/konyak_cli/lib/src/repository/file_bottle_repository_read_operations.dart": [
            "IoResult<Option<BottleRecord>> findBottle(BottleId id)",
            "id: id.value,",
            "fileBottlePath(bottleDirectory, id.value)",
        ],
    }
    for path, expected_terms in expected_repository_terms.items():
        source = read_text(path)
        for expected in expected_terms:
            if expected not in source:
                raise AssertionError(
                    "Bottle repository implementations must preserve typed "
                    f"bottle ids until storage lookup: {expected}"
                )
        for forbidden in ["findBottle(String", "deleteBottle(String"]:
            if forbidden in source:
                raise AssertionError(
                    f"{path} must not expose primitive bottle repository "
                    f"operations: {forbidden}"
                )

    operation_paths = [
        "packages/konyak_cli/lib/src/repository/file_bottle_repository_mutation_operations.dart",
        "packages/konyak_cli/lib/src/repository/file_bottle_repository_archive_operations.dart",
        "packages/konyak_cli/lib/src/repository/file_bottle_repository_program_operations.dart",
    ]
    for path in operation_paths:
        source = read_text(path)
        if "Function(String id) findBottle" in source:
            raise AssertionError(
                f"{path} must not receive primitive bottle lookup callbacks"
            )


def require_typed_runtime_settings_setter_boundary() -> None:
    path = "packages/konyak_cli/lib/src/domain/bottle/bottle_runtime_settings_models.dart"
    source = read_text(path)
    expected_terms = [
        "BottleRuntimeSettings withEnhancedSync(EnhancedSyncMode enhancedSync)",
        "BottleRuntimeSettings withDxvkHud(DxvkHudMode dxvkHud)",
        "return BottleRuntimeSettings._validated(",
        "enhancedSync: enhancedSync,",
        "dxvkHud: dxvkHud,",
    ]
    for expected in expected_terms:
        if expected not in source:
            raise AssertionError(
                "BottleRuntimeSettings update helpers must preserve typed "
                f"runtime settings values: {expected}"
            )

    forbidden_terms = [
        "BottleRuntimeSettings withEnhancedSync(String enhancedSync)",
        "BottleRuntimeSettings withDxvkHud(String dxvkHud)",
    ]
    for forbidden in forbidden_terms:
        if forbidden in source:
            raise AssertionError(
                "BottleRuntimeSettings update helpers must not expose raw "
                f"string settings: {forbidden}"
            )


def require_typed_mutation_model_boundaries() -> None:
    bottle_path = "packages/konyak_cli/lib/src/domain/bottle/bottle_mutation_models.dart"
    bottle_source = read_text(bottle_path)
    expected_bottle_terms = [
        "required BottleName name,",
        "required WindowsVersion windowsVersion,",
        "required BottleId bottleId,",
        "required BottleArchivePath archivePath,",
        "factory BottleArchiveImportRequest({required BottleArchivePath archivePath})",
        "factory BottleCreateConflict(BottleId bottleId)",
        "factory BottleMoveConflict(BottlePath path)",
    ]
    for expected in expected_bottle_terms:
        if expected not in bottle_source:
            raise AssertionError(
                "Bottle mutation models must preserve typed value objects: "
                f"{expected}"
            )

    forbidden_bottle_terms = [
        "required String bottleId",
        "required String name",
        "required String windowsVersion",
        "required String archivePath",
        "factory BottleCreateConflict(String",
        "factory BottleMoveConflict(String",
        "factory BottleUpdateMissing(String",
    ]
    for forbidden in forbidden_bottle_terms:
        if forbidden in bottle_source:
            raise AssertionError(
                "Bottle mutation models must not expose primitive semantic "
                f"values: {forbidden}"
            )

    program_path = "packages/konyak_cli/lib/src/domain/program/program_mutation_models.dart"
    program_source = read_text(program_path)
    expected_program_terms = [
        "required BottleId bottleId,",
        "required ProgramName name,",
        "required ProgramPath programPath,",
        "required ProgramLauncherId launcherId,",
        "required WineProcessId processId,",
        "Option<BottleId> bottleId = const Option.none(),",
        "factory ProgramPinResult.conflict(ProgramPath programPath)",
        "factory ProgramUpdateResult.missingBottle(BottleId bottleId)",
    ]
    for expected in expected_program_terms:
        if expected not in program_source:
            raise AssertionError(
                "Program mutation models must preserve typed value objects: "
                f"{expected}"
            )

    forbidden_program_terms = [
        "required String bottleId",
        "required String programPath",
        "required String name",
        "required String processId",
        "Option<String> bottleId",
        "factory ProgramPinResult.conflict(String",
        "factory ProgramUpdateResult.missingBottle(String",
    ]
    for forbidden in forbidden_program_terms:
        if forbidden in program_source:
            raise AssertionError(
                "Program mutation models must not expose primitive semantic "
                f"values: {forbidden}"
            )

    catalog_path = "packages/konyak_cli/lib/src/domain/program/program_catalog_models.dart"
    catalog_source = read_text(catalog_path)
    if "required String programPath" in catalog_source:
        raise AssertionError(
            "Program metadata extractors must receive ProgramPath, not String"
        )

    pinned_path = "packages/konyak_cli/lib/src/domain/program/pinned_programs.dart"
    pinned_source = read_text(pinned_path)
    expected_pinned_terms = [
        "bool hasPinnedProgram(BottleRecord bottle, ProgramPath programPath)",
        "ProgramPath programPath,",
    ]
    for expected in expected_pinned_terms:
        if expected not in pinned_source:
            raise AssertionError(
                "Pinned program helpers must preserve typed program paths: "
                f"{expected}"
            )

    if "bool hasPinnedProgram(BottleRecord bottle, String programPath)" in pinned_source:
        raise AssertionError("Pinned program helpers must not accept raw program paths")

    graphics_path = (
        "packages/konyak_cli/lib/src/domain/program/program_graphics_backend_hints.dart"
    )
    graphics_source = read_text(graphics_path)
    expected_graphics_terms = [
        "required ProgramPath programPath,",
        "factory ProgramGraphicsBackendHintsInspectionResult.missingProgram(\n    ProgramPath programPath,",
        "required ProgramPath programPath,",
    ]
    for expected in expected_graphics_terms:
        if expected not in graphics_source:
            raise AssertionError(
                "Graphics backend hint APIs must preserve typed program paths: "
                f"{expected}"
            )

    forbidden_graphics_terms = [
        "required String programPath",
        "missingProgram(\n    String programPath",
    ]
    for forbidden in forbidden_graphics_terms:
        if forbidden in graphics_source:
            raise AssertionError(
                "Graphics backend hint APIs must not expose raw program paths: "
                f"{forbidden}"
            )


def require_typed_registry_planner_boundary() -> None:
    registry_model_path = "packages/konyak_cli/lib/src/domain/program/program_registry_models.dart"
    registry_model_source = read_text(registry_model_path)
    expected_model_terms = [
        "required ProgramRegistryKey key,",
        "required ProgramRegistryValueName name,",
        "required ProgramRegistryValueType type,",
        "required ProgramRegistryValueData data,",
    ]
    for expected in expected_model_terms:
        if expected not in registry_model_source:
            raise AssertionError(
                "Registry value models must expose typed registry values: "
                f"{expected}"
            )
    for forbidden in [
        "required String key,",
        "required String name,",
        "required String type,",
        "required String data,",
    ]:
        if forbidden in registry_model_source:
            raise AssertionError(
                "Registry value models must not expose primitive registry "
                f"values: {forbidden}"
            )

    registry_path = "packages/konyak_cli/lib/src/domain/program/program_registry_plans.dart"
    registry_source = read_text(registry_path)
    expected_registry_terms = [
        "List<RegistryValueUpdate> windowsVersionRegistryUpdates(\n  WindowsVersion windowsVersion,",
        "enum RegistryPlanningPolicy",
        "bool get includesMacDriverRegistryValues",
        "required RegistryPlanningPolicy policy,",
        "policy.includesMacDriverRegistryValues",
        "Option<WindowsVersion> _windowsVersionForBuildVersion(int buildVersion)",
        "data: ProgramRegistryValueData(windowsVersion.value),",
    ]
    for expected in expected_registry_terms:
        if expected not in registry_source:
            raise AssertionError(
                "Registry planners must preserve typed Windows versions: "
                f"{expected}"
            )

    forbidden_registry_terms = [
        "List<RegistryValueUpdate> windowsVersionRegistryUpdates(String windowsVersion)",
        "required bool includeMacDriverSettings",
        "Option<String> _windowsVersionForBuildVersion(int buildVersion)",
    ]
    for forbidden in forbidden_registry_terms:
        if forbidden in registry_source:
            raise AssertionError(
                "Registry planners must not expose primitive Windows versions: "
                f"{forbidden}"
            )

    planner_path = "packages/konyak_cli/lib/src/domain/program/program_runner.dart"
    planner_source = read_text(planner_path)
    expected_planner_terms = [
        "required WindowsVersion windowsVersion,",
        "final updates = windowsVersionRegistryUpdates(windowsVersion);",
        "RegistryPlanningPolicy get _registryPlanningPolicy",
        "KonyakHostPlatform.linux => RegistryPlanningPolicy.linuxWine",
        "KonyakHostPlatform.macos => RegistryPlanningPolicy.macosWine",
        "policy: _registryPlanningPolicy",
    ]
    for expected in expected_planner_terms:
        if expected not in planner_source:
            raise AssertionError(
                "ProgramRunPlanner registry updates must preserve typed "
                f"Windows versions: {expected}"
            )

    if "required String windowsVersion" in planner_source:
        raise AssertionError(
            "ProgramRunPlanner registry updates must not expose primitive "
            "Windows versions"
        )
    if "includeMacDriverSettings:" in planner_source:
        raise AssertionError(
            "ProgramRunPlanner registry policy must not pass raw platform "
            "booleans to registry plan helpers"
        )


def require_typed_bottle_location_boundary() -> None:
    location_path = "packages/konyak_cli/lib/src/platform/platform_location_paths.dart"
    location_source = read_text(location_path)
    expected_location_terms = [
        "required BottleLocation location",
        "final normalized = location.value.trim().toLowerCase();",
    ]
    for expected in expected_location_terms:
        if expected not in location_source:
            raise AssertionError(
                "Bottle location path helpers must preserve typed locations: "
                f"{expected}"
            )

    if "required String location" in location_source:
        raise AssertionError(
            "Bottle location path helpers must not expose primitive locations"
        )
    expected_program_location_terms = [
        "String programLocationPath(ProgramPath programPath)",
        "final normalized = normalizeFilesystemPath(programPath.value);",
    ]
    for expected in expected_program_location_terms:
        if expected not in location_source:
            raise AssertionError(
                "Program location path helpers must preserve typed program "
                f"paths: {expected}"
            )

    if "String programLocationPath(String programPath)" in location_source:
        raise AssertionError(
            "Program location path helpers must not expose primitive program paths"
        )

    parser_path = "packages/konyak_cli/lib/src/cli/cli_location_parsers.dart"
    parser_source = read_text(parser_path)
    expected_parser_terms = [
        "final BottleLocation location;",
        "location: BottleLocation(locationValue),",
    ]
    for expected in expected_parser_terms:
        if expected not in parser_source:
            raise AssertionError(
                "Bottle location CLI parser must convert locations once at "
                f"the boundary: {expected}"
            )

    if "final String location;" in parser_source:
        raise AssertionError(
            "Bottle location CLI request must not store primitive locations"
        )
    expected_program_parser_terms = [
        "final ProgramPath programPath;",
        "programPath: ProgramPath(programPathValue),",
    ]
    for expected in expected_program_parser_terms:
        if expected not in parser_source:
            raise AssertionError(
                "Program location CLI parser must convert program paths once "
                f"at the boundary: {expected}"
            )

    if "final String programPath;" in parser_source:
        raise AssertionError(
            "Program location CLI request must not store primitive program paths"
        )

    handler_path = (
        "packages/konyak_cli/lib/src/cli/cli_location_winetricks_handlers.dart"
    )
    handler_source = read_text(handler_path)
    for expected in [
        "location: request.location,",
        "'location': request.location.value",
    ]:
        if expected not in handler_source:
            raise AssertionError(
                "Bottle location handler must keep typed locations until JSON "
                f"projection: {expected}"
            )
    for expected in [
        "hasPinnedProgram(bottle, request.programPath)",
        "final path = request.programPath.value;",
        "'programPath': request.programPath.value",
    ]:
        if expected not in handler_source:
            raise AssertionError(
                "Program location handler must keep typed program paths until "
                f"boundary projection: {expected}"
            )


def require_wine_process_termination_cli_json_projection() -> None:
    domain_path = "packages/konyak_cli/lib/src/domain/program/program_run_models.dart"
    domain = read_text(domain_path)
    record_match = re.search(
        r"\bclass\s+WineProcessTerminationRecord\b(?P<body>.*?)(?=\n"
        r"(?:abstract\s+(?:interface\s+)?|final\s+)?class\s+\w+|\Z)",
        domain,
        flags=re.DOTALL,
    )
    if record_match is None:
        raise AssertionError("WineProcessTerminationRecord must exist")
    if "toJson(" in record_match.group("body"):
        raise AssertionError(
            "WineProcessTerminationRecord must not own CLI JSON projection"
        )
    record_body = record_match.group("body")
    for expected in [
        "required BottleId bottleId,",
        "required WineProcessStatus status,",
        "required RunnerKind runnerKind,",
        "required ProgramExecutable executable,",
        "Option<WineProcessId> processId = const Option.none(),",
    ]:
        if expected not in record_body:
            raise AssertionError(
                "WineProcessTerminationRecord must expose typed process "
                f"termination values: {expected}"
            )
    for forbidden in [
        "required String bottleId,",
        "required String status,",
        "required String runnerKind,",
        "required String executable,",
        "Option<String> processId = const Option.none(),",
    ]:
        if forbidden in record_body:
            raise AssertionError(
                "WineProcessTerminationRecord must not expose primitive "
                f"process termination values: {forbidden}"
            )

    cli_path = "packages/konyak_cli/lib/src/cli/cli_app_process_results.dart"
    cli = read_text(cli_path)
    expected_terms = [
        "Map<String, Object?> wineProcessTerminationRecordJson(",
        "WineProcessTerminationRecord record,",
        "record.processId.match(",
        "record.processExitCode.match(",
        "record.message.match(",
        ".map(wineProcessTerminationRecordJson)",
    ]
    for expected in expected_terms:
        if expected not in cli:
            raise AssertionError(
                "Wine process termination JSON projection must live at the "
                f"CLI boundary: {expected}"
            )

    if "record.toJson()" in cli:
        raise AssertionError(
            "CLI process results must not rely on domain-owned toJson"
        )


def require_program_catalog_cli_json_projection() -> None:
    domain_path = (
        "packages/konyak_cli/lib/src/domain/program/program_catalog_models.dart"
    )
    domain = read_text(domain_path)

    def class_section(class_name: str) -> str:
        class_start = domain.find(f"class {class_name} ")
        if class_start == -1:
            raise AssertionError(f"{class_name} must exist")

        next_class_match = re.search(
            r"\n(?:abstract\s+interface\s+)?class\s+\w+",
            domain[class_start + 1 :],
        )
        if next_class_match is None:
            return domain[class_start:]

        class_end = class_start + 1 + next_class_match.start()
        return domain[class_start:class_end]

    for class_name in [
        "BottleProgramRecord",
        "ProgramMetadataRecord",
        "WineProcessRecord",
        "WinetricksVerbRecord",
        "WinetricksCategoryRecord",
    ]:
        if "toJson(" in class_section(class_name):
            raise AssertionError(
                f"{class_name} must not own CLI JSON projection"
            )

    if "Map<String, Object?> _metadataJsonField(" in domain:
        raise AssertionError("Program metadata JSON helpers must live in CLI")

    cli_catalog_path = (
        "packages/konyak_cli/lib/src/cli/cli_program_catalog_json.dart"
    )
    cli_catalog = read_text(cli_catalog_path)
    expected_terms = [
        "Map<String, Object?> bottleProgramRecordJson(",
        "Map<String, Object?> programMetadataRecordJson(",
        "Map<String, Object?> wineProcessRecordJson(",
        "Map<String, Object?> winetricksVerbRecordJson(",
        "Map<String, Object?> winetricksCategoryRecordJson(",
        "record.metadata.match(",
        "metadata.architecture",
        "metadata.iconPath",
        "category.verbs",
        ".map(winetricksVerbRecordJson)",
    ]
    for expected in expected_terms:
        if expected not in cli_catalog:
            raise AssertionError(
                "Program catalog JSON projection must live at the CLI "
                f"boundary: {expected}"
            )

    bottle_read_path = "packages/konyak_cli/lib/src/cli/cli_bottle_read_handlers.dart"
    bottle_read = read_text(bottle_read_path)
    if ".map((program) => program.toJson())" in bottle_read:
        raise AssertionError(
            "Bottle program list JSON must not rely on domain-owned toJson"
        )
    if ".map(bottleProgramRecordJson)" not in bottle_read:
        raise AssertionError(
            "Bottle program list JSON must use bottleProgramRecordJson"
        )

    process_results_path = (
        "packages/konyak_cli/lib/src/cli/cli_app_process_results.dart"
    )
    process_results = read_text(process_results_path)
    if ".map((processRecord) => processRecord.toJson())" in process_results:
        raise AssertionError(
            "Wine process list JSON must not rely on domain-owned toJson"
        )
    if ".map(wineProcessRecordJson)" not in process_results:
        raise AssertionError(
            "Wine process list JSON must use wineProcessRecordJson"
        )

    winetricks_path = (
        "packages/konyak_cli/lib/src/cli/cli_location_winetricks_handlers.dart"
    )
    winetricks = read_text(winetricks_path)
    if ".map((category) => category.toJson())" in winetricks:
        raise AssertionError(
            "Winetricks catalog JSON must not rely on domain-owned toJson"
        )
    if ".map(winetricksCategoryRecordJson)" not in winetricks:
        raise AssertionError(
            "Winetricks catalog JSON must use winetricksCategoryRecordJson"
        )


def require_graphics_backend_hints_cli_json_projection() -> None:
    domain_path = (
        "packages/konyak_cli/lib/src/domain/program/"
        "program_graphics_backend_hints.dart"
    )
    domain = read_text(domain_path)

    def class_section(class_name: str) -> str:
        class_match = re.search(
            rf"\b(?:abstract\s+interface\s+|sealed\s+|abstract\s+|final\s+)*"
            rf"class\s+{re.escape(class_name)}\b",
            domain,
        )
        if class_match is None:
            raise AssertionError(f"{class_name} must exist")
        class_start = class_match.start()

        next_class_match = re.search(
            r"\n(?:abstract\s+interface\s+|sealed\s+|abstract\s+|final\s+)*"
            r"class\s+\w+",
            domain[class_start + 1 :],
        )
        if next_class_match is None:
            return domain[class_start:]

        class_end = class_start + 1 + next_class_match.start()
        return domain[class_start:class_end]

    for class_name in [
        "ProgramGraphicsBackendHints",
        "ProgramGraphicsBackendSignal",
        "ProgramGraphicsBackendSuggestion",
    ]:
        if "toJson(" in class_section(class_name):
            raise AssertionError(
                f"{class_name} must not own CLI JSON projection"
            )
    for class_name, expected_terms, forbidden_terms in [
        (
            "ProgramGraphicsBackendSignal",
            [
                "required GraphicsBackendSignalKind kind,",
                "required GraphicsBackendSignalValue value,",
            ],
            ["required String kind,", "required String value,"],
        ),
        (
            "ProgramGraphicsBackendSuggestion",
            [
                "required GraphicsBackendKind backend,",
                "required GraphicsBackendConfidence confidence,",
            ],
            ["required String backend,", "required String confidence,"],
        ),
    ]:
        section = class_section(class_name)
        for expected in expected_terms:
            if expected not in section:
                raise AssertionError(
                    f"{class_name} must expose typed graphics values: "
                    f"{expected}"
                )
        for forbidden in forbidden_terms:
            if forbidden in section:
                raise AssertionError(
                    f"{class_name} must not expose primitive graphics values: "
                    f"{forbidden}"
                )

    if "_hostPlatformJsonValue(" in domain:
        raise AssertionError("Graphics backend host platform JSON must live in CLI")

    cli_json_path = (
        "packages/konyak_cli/lib/src/cli/"
        "cli_program_graphics_backend_hints_json.dart"
    )
    cli_json = read_text(cli_json_path)
    expected_terms = [
        "Map<String, Object?> programGraphicsBackendHintsJson(",
        "Map<String, Object?> programGraphicsBackendSignalJson(",
        "Map<String, Object?> programGraphicsBackendSuggestionJson(",
        "hints.signals",
        ".map(programGraphicsBackendSignalJson)",
        "hints.suggestions",
        ".map(programGraphicsBackendSuggestionJson)",
        "KonyakHostPlatform.macos => 'macos'",
        "KonyakHostPlatform.linux => 'linux'",
    ]
    for expected in expected_terms:
        if expected not in cli_json:
            raise AssertionError(
                "Graphics backend hints JSON projection must live at the CLI "
                f"boundary: {expected}"
            )

    handler_path = "packages/konyak_cli/lib/src/cli/cli_program_run_handlers.dart"
    handler = read_text(handler_path)
    if "hints.toJson()" in handler:
        raise AssertionError(
            "Graphics backend hints JSON must not rely on domain-owned toJson"
        )
    if "programGraphicsBackendHintsJson(hints)" not in handler:
        raise AssertionError(
            "Graphics backend hints JSON must use "
            "programGraphicsBackendHintsJson"
        )


def require_program_settings_cli_json_projection() -> None:
    domain_path = (
        "packages/konyak_cli/lib/src/domain/program/program_settings_models.dart"
    )
    domain = read_text(domain_path)

    def class_section(class_name: str) -> str:
        class_match = re.search(rf"\bclass\s+{class_name}\b", domain)
        if class_match is None:
            raise AssertionError(f"{class_name} must exist")
        class_start = class_match.start()

        next_class_match = re.search(
            r"\n(?:abstract\s+(?:interface\s+)?|final\s+)?class\s+\w+",
            domain[class_start + 1 :],
        )
        if next_class_match is None:
            return domain[class_start:]

        class_end = class_start + 1 + next_class_match.start()
        return domain[class_start:class_end]

    for class_name in [
        "ProgramSettingsRecord",
        "ProgramLoggingSettingsRecord",
    ]:
        if "toJson(" in class_section(class_name):
            raise AssertionError(
                f"{class_name} must not own CLI JSON projection"
            )

    json_path = "packages/konyak_cli/lib/src/io/program_settings_json.dart"
    json_projection = read_text(json_path)
    expected_terms = [
        "Map<String, Object?> programSettingsRecordJson(",
        "Map<String, Object?> programLoggingSettingsRecordJson(",
        "settings.logging.match(",
        "settings.environment.toMap()",
        "logging.additionalWineLoggingChannels.value",
        "logging.logFilePath.value",
    ]
    for expected in expected_terms:
        if expected not in json_projection:
            raise AssertionError(
                "Program settings JSON projection must live at the "
                f"boundary: {expected}"
            )

    handler_path = "packages/konyak_cli/lib/src/cli/cli_program_results.dart"
    handler = read_text(handler_path)
    if "settings.toJson()" in handler:
        raise AssertionError(
            "Program settings JSON must not rely on domain-owned toJson"
        )
    if "programSettingsRecordJson(settings)" not in handler:
        raise AssertionError(
            "Program settings JSON must use programSettingsRecordJson"
        )

    storage_path = "packages/konyak_cli/lib/src/io/repository_storage_io.dart"
    storage = read_text(storage_path)
    if "settings.toJson()" in storage:
        raise AssertionError(
            "Program settings storage JSON must not rely on domain-owned toJson"
        )
    if "programSettingsRecordJson(settings)" not in storage:
        raise AssertionError(
            "Program settings storage JSON must use programSettingsRecordJson"
        )


def require_app_settings_serialization_boundary() -> None:
    domain_path = "packages/konyak_cli/lib/src/domain/app/app_settings_models.dart"
    domain = read_text(domain_path)
    record_start = domain.find("class AppSettingsRecord ")
    if record_start == -1:
        raise AssertionError("AppSettingsRecord must exist")
    if "toJson(" in domain[record_start:]:
        raise AssertionError(
            "AppSettingsRecord must not own JSON projection"
        )
    if "jsonValue" in domain:
        raise AssertionError(
            "App settings enum JSON values must live at the serialization "
            "boundary"
        )

    json_path = "packages/konyak_cli/lib/src/io/app_settings_json.dart"
    json_projection = read_text(json_path)
    expected_terms = [
        "Map<String, Object?> appSettingsRecordJson(",
        "String appAppearanceModeJsonValue(",
        "String appLanguageModeJsonValue(",
        "Option<AppAppearanceMode> appAppearanceModeFromJson(",
        "Option<AppLanguageMode> appLanguageModeFromJson(",
        "settings.defaultBottlePath.value",
        "AppAppearanceMode.light => 'light'",
        "AppLanguageMode.japanese => 'ja'",
    ]
    for expected in expected_terms:
        if expected not in json_projection:
            raise AssertionError(
                "App settings JSON projection must live at the serialization "
                f"boundary: {expected}"
            )

    cli_path = "packages/konyak_cli/lib/src/cli/cli_app_process_results.dart"
    cli = read_text(cli_path)
    if "settings.toJson()" in cli:
        raise AssertionError(
            "App settings CLI JSON must not rely on domain-owned toJson"
        )
    if "appSettingsRecordJson(settings)" not in cli:
        raise AssertionError(
            "App settings CLI JSON must use appSettingsRecordJson"
        )

    storage_path = "packages/konyak_cli/lib/src/io/app_settings_repositories.dart"
    storage = read_text(storage_path)
    if "settings.toJson()" in storage:
        raise AssertionError(
            "App settings storage JSON must not rely on domain-owned toJson"
        )
    if "appSettingsRecordJson(settings)" not in storage:
        raise AssertionError(
            "App settings storage JSON must use appSettingsRecordJson"
        )


def require_update_record_cli_json_projection() -> None:
    domain_path = "packages/konyak_cli/lib/src/domain/update/update_records.dart"
    domain = read_text(domain_path)

    def class_section(class_name: str) -> str:
        class_start = domain.find(f"class {class_name} ")
        if class_start == -1:
            raise AssertionError(f"{class_name} must exist")

        next_class_match = re.search(
            r"\n(?:abstract\s+interface\s+)?(?:final\s+)?class\s+\w+",
            domain[class_start + 1 :],
        )
        if next_class_match is None:
            return domain[class_start:]

        class_end = class_start + 1 + next_class_match.start()
        return domain[class_start:class_end]

    for class_name in [
        "RuntimeUpdateRecord",
        "AppUpdateRecord",
        "AppUpdateInstallRecord",
    ]:
        if "toJson(" in class_section(class_name):
            raise AssertionError(
                f"{class_name} must not own CLI JSON projection"
            )

    for class_name, expected_terms, forbidden_terms in [
        (
            "RuntimeUpdateRecord",
            [
                "required RuntimeId runtimeId,",
                "required UpdateCheckStatus status,",
                "Option<RuntimeVersion> currentVersion =",
                "Option<RuntimeArchiveUrl> archiveUrl =",
                "Option<RuntimeSourceManifestUrl> sourceManifestUrl =",
            ],
            [
                "required String runtimeId,",
                "required String status,",
                "Option<String> currentVersion =",
                "Option<String> archiveUrl =",
                "Option<String> sourceManifestUrl =",
            ],
        ),
        (
            "AppUpdateRecord",
            [
                "required AppId appId,",
                "required UpdateCheckStatus status,",
                "Option<AppVersion> currentVersion =",
                "Option<ReleaseVersion> latestVersion =",
                "Option<AppArchiveUrl> archiveUrl =",
            ],
            [
                "required String appId,",
                "required String status,",
                "Option<String> currentVersion =",
                "Option<String> latestVersion =",
                "Option<String> archiveUrl =",
            ],
        ),
        (
            "AppUpdateInstallRecord",
            [
                "required AppId appId,",
                "required UpdateInstallStatus status,",
                "Option<AppVersion> currentVersion =",
                "Option<AppInstallPath> installPath =",
            ],
            [
                "required String appId,",
                "required String status,",
                "Option<String> currentVersion =",
                "Option<String> installPath =",
            ],
        ),
        (
            "RuntimeReleaseMetadata",
            [
                "required ReleaseVersion version,",
                "Option<RuntimeArchiveUrl> archiveUrl =",
                "Option<RuntimeArchiveChecksumValue> archiveSha256 =",
                "Option<RuntimeSourceManifestUrl> sourceManifestUrl =",
            ],
            [
                "required String version,",
                "Option<String> archiveUrl =",
                "Option<String> archiveSha256 =",
                "Option<String> sourceManifestUrl =",
            ],
        ),
    ]:
        section = class_section(class_name)
        for expected in expected_terms:
            if expected not in section:
                raise AssertionError(
                    f"{class_name} must expose typed update values: {expected}"
                )
        for forbidden in forbidden_terms:
            if forbidden in section:
                raise AssertionError(
                    f"{class_name} must not expose primitive update values: "
                    f"{forbidden}"
                )

    if "Map<String, Object?> _updateJsonField(" in domain:
        raise AssertionError("Update JSON helpers must live in CLI")

    cli_json_path = "packages/konyak_cli/lib/src/cli/cli_update_json.dart"
    cli_json = read_text(cli_json_path)
    expected_terms = [
        "Map<String, Object?> runtimeUpdateRecordJson(",
        "Map<String, Object?> appUpdateRecordJson(",
        "Map<String, Object?> appUpdateInstallRecordJson(",
        "'sourceManifestSignatureUrl'",
        "'archiveSha256'",
        "'installPath'",
    ]
    for expected in expected_terms:
        if expected not in cli_json:
            raise AssertionError(
                "Update record JSON projection must live at the CLI boundary: "
                f"{expected}"
            )

    app_results_path = "packages/konyak_cli/lib/src/cli/cli_app_process_results.dart"
    app_results = read_text(app_results_path)
    if "update.toJson()" in app_results or "install.toJson()" in app_results:
        raise AssertionError(
            "App update JSON must not rely on domain-owned toJson"
        )
    if "appUpdateRecordJson(update)" not in app_results:
        raise AssertionError("App update JSON must use appUpdateRecordJson")
    if "appUpdateInstallRecordJson(install)" not in app_results:
        raise AssertionError(
            "App update install JSON must use appUpdateInstallRecordJson"
        )

    runtime_results_path = (
        "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart"
    )
    runtime_results = read_text(runtime_results_path)
    if "update.toJson()" in runtime_results:
        raise AssertionError(
            "Runtime update JSON must not rely on domain-owned toJson"
        )
    if "runtimeUpdateRecordJson(update)" not in runtime_results:
        raise AssertionError(
            "Runtime update JSON must use runtimeUpdateRecordJson"
        )


def require_runtime_validation_cli_json_projection() -> None:
    domain_path = (
        "packages/konyak_cli/lib/src/domain/runtime/runtime_validation_models.dart"
    )
    domain = read_text(domain_path)

    def class_section(class_name: str) -> str:
        class_start = domain.find(f"class {class_name} ")
        if class_start == -1:
            raise AssertionError(f"{class_name} must exist")

        next_class_match = re.search(
            r"\n(?:abstract\s+interface\s+)?(?:final\s+)?class\s+\w+",
            domain[class_start + 1 :],
        )
        if next_class_match is None:
            return domain[class_start:]

        class_end = class_start + 1 + next_class_match.start()
        return domain[class_start:class_end]

    for class_name in [
        "RuntimeValidationRecord",
        "RuntimeValidationCheck",
    ]:
        if "toJson(" in class_section(class_name):
            raise AssertionError(
                f"{class_name} must not own CLI JSON projection"
            )

    cli_json_path = (
        "packages/konyak_cli/lib/src/cli/cli_runtime_validation_json.dart"
    )
    cli_json = read_text(cli_json_path)
    expected_terms = [
        "Map<String, Object?> runtimeValidationRecordJson(",
        "Map<String, Object?> runtimeValidationCheckJson(",
        "'runtimeId': validation.runtimeId.value",
        "'isValid': validation.isValid",
        "validation.checks",
        ".map(runtimeValidationCheckJson)",
        "'isRequired': check.isRequired",
        "'isPassed': check.isPassed",
    ]
    for expected in expected_terms:
        if expected not in cli_json:
            raise AssertionError(
                "Runtime validation JSON projection must live at the CLI "
                f"boundary: {expected}"
            )

    handler_path = "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart"
    handler = read_text(handler_path)
    if "validation.toJson()" in handler:
        raise AssertionError(
            "Runtime validation JSON must not rely on domain-owned toJson"
        )
    if "runtimeValidationRecordJson(validation)" not in handler:
        raise AssertionError(
            "Runtime validation JSON must use runtimeValidationRecordJson"
        )


def require_runtime_install_progress_io_json_projection() -> None:
    domain_path = (
        "packages/konyak_cli/lib/src/domain/runtime/runtime_package_installation.dart"
    )
    domain = read_text(domain_path)
    class_start = domain.find("class RuntimeInstallProgress ")
    if class_start == -1:
        raise AssertionError("RuntimeInstallProgress must exist")
    next_class_match = re.search(
        r"\n(?:abstract\s+interface\s+)?(?:abstract\s+)?(?:sealed\s+)?"
        r"(?:final\s+)?class\s+\w+",
        domain[class_start + 1 :],
    )
    if next_class_match is None:
        record_section = domain[class_start:]
    else:
        class_end = class_start + 1 + next_class_match.start()
        record_section = domain[class_start:class_end]
    if "toJson(" in record_section:
        raise AssertionError(
            "RuntimeInstallProgress must not own JSON projection"
        )

    io_path = "packages/konyak_cli/lib/src/io/runtime_install_progress_io.dart"
    io = read_text(io_path)
    expected_terms = [
        "Map<String, Object?> runtimeInstallProgressJson(",
        "'stage': progress.stage.value",
        "'message': progress.message",
        "'fraction': progress.fraction.value",
        "'runtimeInstallProgress': runtimeInstallProgressJson(progress)",
    ]
    for expected in expected_terms:
        if expected not in io:
            raise AssertionError(
                "Runtime install progress JSON projection must live at the "
                f"I/O boundary: {expected}"
            )

    if "progress.toJson()" in io:
        raise AssertionError(
            "Runtime install progress sink must not rely on domain-owned toJson"
        )


def require_runtime_record_cli_json_projection() -> None:
    domain_path = "packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart"
    domain = read_text(domain_path)

    def class_section(class_name: str) -> str:
        class_start = domain.find(f"class {class_name} ")
        if class_start == -1:
            raise AssertionError(f"{class_name} must exist")

        next_class_match = re.search(
            r"\n(?:abstract\s+interface\s+)?(?:final\s+)?class\s+\w+",
            domain[class_start + 1 :],
        )
        if next_class_match is None:
            return domain[class_start:]

        class_end = class_start + 1 + next_class_match.start()
        return domain[class_start:class_end]

    for class_name in [
        "RuntimeRecord",
        "RuntimeStack",
        "RuntimeStackBackend",
        "RuntimeStackComponent",
    ]:
        if "toJson(" in class_section(class_name):
            raise AssertionError(
                f"{class_name} must not own CLI JSON projection"
            )

    if "runtimeStackSchemaVersion" in domain:
        raise AssertionError(
            "Runtime stack schema constants must live at the CLI JSON boundary"
        )
    if "_runtimeJsonStringField(" in domain:
        raise AssertionError("Runtime JSON helpers must live in CLI")

    cli_json_path = "packages/konyak_cli/lib/src/cli/cli_runtime_record_json.dart"
    cli_json = read_text(cli_json_path)
    expected_terms = [
        "Map<String, Object?> runtimeRecordJson(",
        "Map<String, Object?> runtimeStackJson(",
        "Map<String, Object?> runtimeStackBackendJson(",
        "Map<String, Object?> runtimeStackComponentJson(",
        "'id': runtime.id.value",
        "'schemaVersion': runtimeStackSchemaVersion",
        "runtime.stack.match(",
        "stack.components",
        ".map(runtimeStackComponentJson)",
        "stack.backends",
        ".map(runtimeStackBackendJson)",
        "component.version",
    ]
    for expected in expected_terms:
        if expected not in cli_json:
            raise AssertionError(
                "Runtime record JSON projection must live at the CLI boundary: "
                f"{expected}"
            )

    handler_path = "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart"
    handler = read_text(handler_path)
    if ".map((runtime) => runtime.toJson())" in handler:
        raise AssertionError(
            "Runtime list JSON must not rely on domain-owned toJson"
        )
    if ".map(runtimeRecordJson)" not in handler:
        raise AssertionError("Runtime list JSON must use runtimeRecordJson")

    runtime_results_path = (
        "packages/konyak_cli/lib/src/cli/cli_update_runtime_results.dart"
    )
    runtime_results = read_text(runtime_results_path)
    if "runtime.toJson()" in runtime_results:
        raise AssertionError(
            "Runtime result JSON must not rely on domain-owned toJson"
        )
    if "runtimeRecordJson(runtime)" not in runtime_results:
        raise AssertionError("Runtime result JSON must use runtimeRecordJson")


def require_bottle_metadata_io_json_projection() -> None:
    bottle_path = "packages/konyak_cli/lib/src/domain/bottle/bottle_models.dart"
    bottle_domain = read_text(bottle_path)

    def bottle_class_section(class_name: str) -> str:
        class_start = bottle_domain.find(f"class {class_name} ")
        if class_start == -1:
            raise AssertionError(f"{class_name} must exist")

        next_class_match = re.search(
            r"\n(?:abstract\s+interface\s+)?(?:final\s+)?class\s+\w+",
            bottle_domain[class_start + 1 :],
        )
        if next_class_match is None:
            return bottle_domain[class_start:]

        class_end = class_start + 1 + next_class_match.start()
        return bottle_domain[class_start:class_end]

    for class_name in [
        "BottleRecord",
        "PinnedProgramRecord",
    ]:
        if "toJson(" in bottle_class_section(class_name):
            raise AssertionError(f"{class_name} must not own JSON projection")

    runtime_settings_path = (
        "packages/konyak_cli/lib/src/domain/bottle/"
        "bottle_runtime_settings_models.dart"
    )
    runtime_settings_domain = read_text(runtime_settings_path)
    runtime_settings_start = runtime_settings_domain.find(
        "class BottleRuntimeSettings "
    )
    if runtime_settings_start == -1:
        raise AssertionError("BottleRuntimeSettings must exist")
    if "toJson(" in runtime_settings_domain[runtime_settings_start:]:
        raise AssertionError(
            "BottleRuntimeSettings must not own JSON projection"
        )

    io_path = "packages/konyak_cli/lib/src/io/bottle_metadata_json.dart"
    io = read_text(io_path)
    expected_terms = [
        "Map<String, Object?> bottleRecordJson(",
        "Map<String, Object?> pinnedProgramRecordJson(",
        "Map<String, Object?> bottleRuntimeSettingsJson(",
        "'id': bottle.id.value",
        "'runtimeSettings': bottleRuntimeSettingsJson(bottle.runtimeSettings)",
        "bottle.pinnedPrograms",
        ".map(pinnedProgramRecordJson)",
        "'iconPath': value.value",
        "'enhancedSync': settings.enhancedSync.value",
        "'dpiScaling': settings.dpiScaling.value",
    ]
    for expected in expected_terms:
        if expected not in io:
            raise AssertionError(
                "Bottle metadata JSON projection must live at the I/O "
                f"boundary: {expected}"
            )

    for caller_path, expected in [
        (
            "packages/konyak_cli/lib/src/cli/cli_bottle_results.dart",
            "bottleRecordJson(bottle)",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_bottle_read_handlers.dart",
            ".map(bottleRecordJson)",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_bottle_mutation_handlers.dart",
            "'deletedBottle': bottleRecordJson(bottle)",
        ),
        (
            "packages/konyak_cli/lib/src/io/repository_storage_io.dart",
            "'bottle': bottleRecordJson(bottle)",
        ),
    ]:
        caller = read_text(caller_path)
        if "bottle.toJson()" in caller:
            raise AssertionError(
                "Bottle JSON callers must not rely on domain-owned toJson"
            )
        if expected not in caller:
            raise AssertionError(
                f"Bottle JSON caller must use bottle metadata projection: {expected}"
            )


def require_bottle_archive_cli_json_projection() -> None:
    domain_path = (
        "packages/konyak_cli/lib/src/domain/bottle/bottle_mutation_models.dart"
    )
    domain = read_text(domain_path)
    record_match = re.search(
        r"\bclass\s+BottleArchiveRecord\b(?P<body>.*?)(?=\n(?:@Freezed|sealed class|abstract class|class )|\Z)",
        domain,
        flags=re.DOTALL,
    )
    if record_match is None:
        raise AssertionError("BottleArchiveRecord must exist")
    if "toJson(" in record_match.group("body"):
        raise AssertionError(
            "BottleArchiveRecord must not own CLI JSON projection"
        )

    cli_path = "packages/konyak_cli/lib/src/cli/cli_bottle_results.dart"
    cli = read_text(cli_path)
    expected_terms = [
        "Map<String, Object?> bottleArchiveRecordJson(",
        "'bottleId': archive.bottleId.value",
        "'archivePath': archive.archivePath.value",
        "'bottleArchive': bottleArchiveRecordJson(archive)",
    ]
    for expected in expected_terms:
        if expected not in cli:
            raise AssertionError(
                "Bottle archive JSON projection must live at the CLI "
                f"boundary: {expected}"
            )

    if "archive.toJson()" in cli:
        raise AssertionError(
            "Bottle archive JSON must not rely on domain-owned toJson"
        )


def require_pinned_launcher_manifest_io_json_projection() -> None:
    domain_path = (
        "packages/konyak_cli/lib/src/domain/program/program_mutation_models.dart"
    )
    domain = read_text(domain_path)
    record_match = re.search(
        r"(?:abstract\s+)?class PinnedProgramLauncherManifest[^{]*\{(?P<body>.*?)\n\}",
        domain,
        flags=re.DOTALL,
    )
    if record_match is None:
        raise AssertionError("PinnedProgramLauncherManifest must exist")
    if "toJson(" in record_match.group("body"):
        raise AssertionError(
            "PinnedProgramLauncherManifest must not own JSON projection"
        )
    if "../../shared/model_constants.dart" in domain:
        raise AssertionError(
            "Pinned launcher manifest model constants must live at the I/O "
            "serialization boundary"
        )

    manifest_path = (
        "packages/konyak_cli/lib/src/io/macos_pinned_launcher_manifests.dart"
    )
    manifest_io = read_text(manifest_path)
    expected_terms = [
        "Map<String, Object?> pinnedProgramLauncherManifestJson(",
        "'schemaVersion': cliSchemaVersion",
        "'createdBy': konyakMacosBundleIdentifier",
        "'launcherId': manifest.launcherId.value",
        "'bottleId': manifest.bottleId.value",
        "'programPath': manifest.programPath.value",
        "'programName': manifest.programName.value",
        "pinnedProgramLauncherManifestFromPayload(",
    ]
    for expected in expected_terms:
        if expected not in manifest_io:
            raise AssertionError(
                "Pinned launcher manifest JSON projection must live at the "
                f"I/O boundary: {expected}"
            )

    for caller_path in [
        "packages/konyak_cli/lib/src/io/macos_pinned_launchers.dart",
        "packages/konyak_cli/lib/src/io/linux_pinned_launchers.dart",
    ]:
        caller = read_text(caller_path)
        if "manifest.toJson()" in caller:
            raise AssertionError(
                "Pinned launcher writers must not rely on domain-owned toJson"
            )
        if "pinnedProgramLauncherManifestJson(manifest)" not in caller:
            raise AssertionError(
                "Pinned launcher writers must use "
                "pinnedProgramLauncherManifestJson"
            )


def count_constructor_field_parameters(
    relative_path: str,
    constructor_name: str,
) -> int:
    text = read_text(relative_path)
    match = re.search(
        rf"\b(?:const\s+)?{re.escape(constructor_name)}"
        r"\s*\(\s*\{(?P<body>.*?)\n\s*\}\s*\);",
        text,
        flags=re.DOTALL,
    )
    if match is None:
        raise AssertionError(
            f"{relative_path} must define a named-parameter constructor for {constructor_name}"
        )

    return len(re.findall(r"\bthis\.", match.group("body")))


def require_flutter_home_contract_boundaries() -> None:
    for relative_path, class_name, limit in [
        ("apps/konyak/lib/src/app/home/home_screen.dart", "KonyakHome", 6),
        (
            "apps/konyak/lib/src/app/bottles/bottle_detail.dart",
            "KonyakBottleDetail",
            6,
        ),
    ]:
        count = count_constructor_field_parameters(relative_path, class_name)
        if count > limit:
            raise AssertionError(
                f"{relative_path} {class_name} constructor has {count} direct props; "
                f"use responsibility-scoped contract objects and keep it at or below {limit}"
            )


def require_flutter_view_model_extraction_boundaries() -> None:
    for relative_path in [
        "apps/konyak/lib/src/app/bottles/bottle_detail_view_model.dart",
        "apps/konyak/lib/src/app/bottles/bottle_configuration_view_model.dart",
        "apps/konyak/lib/src/app/programs/program_configuration_view_model.dart",
        "apps/konyak/test/app/bottle_detail_view_model_test.dart",
        "apps/konyak/test/app/bottle_configuration_view_model_test.dart",
        "apps/konyak/test/app/program_configuration_view_model_test.dart",
    ]:
        if not (ROOT / relative_path).exists():
            raise AssertionError(
                f"{relative_path} must exist to keep R3 view model extraction covered"
            )

    detail_widget = "apps/konyak/lib/src/app/bottles/bottle_detail.dart"
    require_contains(detail_widget, "final viewModel = bottleDetailViewModel(")
    require_not_contains(detail_widget, "state.content")

    configuration_widget = (
        "apps/konyak/lib/src/app/bottles/bottle_configuration_view.dart"
    )
    require_contains(
        configuration_widget,
        "final viewModel = bottleConfigurationViewModel(",
    )
    for forbidden in [
        "resolveBottleRuntimeControlAvailability(",
        "canChangeRuntimeSettings(",
        "hasPendingRuntimeSettings(",
    ]:
        require_not_contains(configuration_widget, forbidden)

    program_widget = "apps/konyak/lib/src/app/programs/program_configuration_view.dart"
    require_contains(program_widget, "final viewModel = programConfigurationViewModel(")
    require_contains(program_widget, "resolveProgramConfigurationSave(")
    require_not_contains(program_widget, "canChangeProgramSettings(")

    require_contains(
        "apps/konyak/lib/src/app/bottles/bottle_configuration_view_model.dart",
        "resolveBottleRuntimeControlAvailability(",
    )
    require_contains(
        "apps/konyak/lib/src/app/bottles/bottle_configuration_view_model.dart",
        "resolveBottleConfigurationRuntimeSettingsChange(",
    )
    require_contains(
        "apps/konyak/lib/src/app/programs/program_configuration_view_model.dart",
        "canChangeProgramSettings(",
    )
    require_contains(
        "apps/konyak/lib/src/app/programs/program_configuration_view_model.dart",
        "resolveProgramConfigurationSave(",
    )


def require_refactoring_documentation_cleanup() -> None:
    for expected in [
        "## Refactoring Milestones",
        "### I1: Compatibility Interface Cleanup",
        "#### PR Gate: I1-P1 CLI Parser Compatibility Wrappers",
        "branch: `task/interface-i1-cli-parser-wrappers`",
        "#### PR Gate: I1-P2 CLI Command Dispatch",
        "branch: `task/interface-i1-cli-command-dispatch`",
        "#### PR Gate: I1-P3 Flutter Dialog and Picker Decisions",
        "branch: `task/interface-i1-flutter-dialog-decisions`",
        "#### PR Gate: I1-P4 Flutter JSON DTO Optional Fields",
        "branch: `task/interface-i1-flutter-json-dtos`",
        "#### PR Gate: I1-P5 Refactoring Governance Allowance Cleanup",
        "branch: `task/interface-i1-governance-allowances`",
        "### I2: Boundary Hardening and Test Contract Cleanup",
        "#### PR Gate: I2-P1 Primitive Boundary Audit",
        "status: completed",
        "branch: `task/interface-i2-primitive-boundary-audit`",
        "#### PR Gate: I2-P2 CLI Contract Seed Test Part Split",
        "status: completed",
        "branch: `task/interface-i2-cli-contract-seed-tests`",
        "#### PR Gate: I2-P3 CLI Contract Family Test Part Split",
        (
            "#### PR Gate: I2-P3 CLI Contract Family Test Part Split\n\n"
            "status: completed\n"
            "branch: `task/interface-i2-cli-contract-family-tests`"
        ),
        "branch: `task/interface-i2-cli-contract-family-tests`",
        "#### PR Gate: I2-P4 Semantic Constructor Primitive Fronts",
        "branch: `task/interface-i2-semantic-constructor-fronts`",
        "#### PR Gate: I2-P5 Command Selection Planner Reassessment",
        "branch: `task/interface-i2-command-selection-planner-audit`",
        "#### PR Gate: I2-P6 Planner Policy Split Plan",
        "branch: `task/interface-i2-planner-policy-split-plan`",
        "#### PR Gate: I2-P7 Registry Planner Platform Policy",
        "branch: `task/interface-i2-registry-platform-policy`",
        "#### PR Gate: I2-P8 Governance and Custom Lint Tightening",
        "branch: `task/interface-i2-governance-tightening`",
        "### I3: Mechanical Type-Safety Hardening",
        "Medium milestones, one PR unit each:",
        "#### PR Gate: I3-P1 Type-Safety Inventory and Gate Order",
        "branch: `task/type-safety-i3-inventory`",
        "#### PR Gate: I3-P2 Runner Kind Typed Catalog",
        "branch: `task/type-safety-i3-runner-kind-catalog`",
        "#### PR Gate: I3-P3 Runtime Platform Definition Type Fronts",
        "branch: `task/type-safety-i3-runtime-platform-definitions`",
        "#### PR Gate: I3-P4 Runtime Model and Source Manifest Type Fronts",
        "branch: `task/type-safety-i3-runtime-model-fronts`",
        "#### PR Gate: I3-P5 Runtime Install Request Type Fronts",
        "branch: `task/type-safety-i3-runtime-install-requests`",
        "#### PR Gate: I3-P6 macOS Version Capability Type Front",
        "branch: `task/type-safety-i3-macos-version-capability`",
        "#### PR Gate: I3-P7 Type-Safety Governance and Lint Guardrails",
        "branch: `task/type-safety-i3-governance`",
    ]:
        require_contains("docs/todo.md", expected)

    for expected in [
        "# I3 Type-Safety Inventory",
        "## Inventory Basis",
        "## Mechanical Conversion PRs",
        "## Allowed Adapter Boundaries",
        "## Deferred Design Decisions",
        "## Next Gate Order",
        "`RunnerKind('<literal>')`",
        "`RuntimePlatformSpec`",
        "`RuntimeDefinition`",
        "`MacosWineInstallRequest`",
        "`LinuxWineInstallRequest`",
        "`Option<int> macosMajorVersion`",
        "I3-P7",
    ]:
        require_contains("docs/i3-type-safety-inventory.md", expected)

    for expected in [
        "# I2 Primitive Boundary Audit",
        "## Hand-Written Test Parts",
        "## Nullable Boundaries",
        "## Primitive Domain Values",
        "## Governance And Lint State",
        "## Next Gate Order",
        "CLI contract tests are now standalone libraries",
        "no `*.part.dart` files remain under `packages/konyak_cli/test`",
        "`konyak_no_nullable_cli_command_handler`",
        "`RuntimePlatformSpec`",
        "`ProgramRunPlanner`",
    ]:
        require_contains("docs/i2-primitive-boundary-audit.md", expected)

    for expected in [
        "# I2 Planner Policy Split Audit",
        "## Planner Host Dispatch",
        "## Runner Kind Policy",
        "## Registry Policy",
        "## Graphics Backend Policy",
        "## Platform Request Builder Duplication",
        "## Completed Gate Decision",
        "`ProgramRunPlanner`",
        "`RegistryPlanningPolicy`",
        "I2-P7",
    ]:
        require_contains("docs/i2-planner-policy-split-audit.md", expected)
    require_not_contains(
        "docs/i2-planner-policy-split-audit.md",
        "`includeMacDriverSettings`",
    )

    for unexpected in [
        "R3-P2 Bottle View Model Extraction",
        "R4-P1 Refactoring Governance",
        "task/refactor-r3-bottle-view-models",
        "task/refactor-r4-governance",
    ]:
        require_not_contains("docs/todo.md", unexpected)

    for stale_branch in [
        "task/refactor-r1-",
        "task/refactor-r2-",
        "task/refactor-r3-",
    ]:
        require_not_contains("docs/progress.md", stale_branch)
    require_contains(
        "docs/progress.md",
        "I3-P4 Runtime Model and Source Manifest Type Fronts",
    )
    require_contains(
        "docs/progress.md",
        "task/type-safety-i3-runtime-model-fronts",
    )

    for relative_path in [
        "packages/konyak_cli/test/cli_contract_executable_test.dart",
        "packages/konyak_cli/test/cli_contract_command_dispatch_test.dart",
        "packages/konyak_cli/test/cli_contract_repository_runner_test.dart",
        "packages/konyak_cli/test/support/cli_contract_helpers.dart",
        "packages/konyak_cli/test/cli_contract_app_bottle_test.dart",
        "packages/konyak_cli/test/cli_contract_pinned_program_test.dart",
        "packages/konyak_cli/test/cli_contract_program_execution_test.dart",
        "packages/konyak_cli/test/cli_contract_runtime_process_update_test.dart",
        "packages/konyak_cli/test/cli_contract_runtime_install_test.dart",
        "packages/konyak_cli/test/support/cli_contract_full_helpers.dart",
    ]:
        if not (ROOT / relative_path).exists():
            raise AssertionError(f"{relative_path} must exist after I2-P3")

    for path in sorted((ROOT / "packages/konyak_cli/test").glob("*.part.dart")):
        relative_path = path.relative_to(ROOT)
        raise AssertionError(f"{relative_path} must not reintroduce CLI test parts")

    cli_contract_test = read_text("packages/konyak_cli/test/cli_contract_test.dart")
    for forbidden in ["part '", 'part "', "part of "]:
        if forbidden in cli_contract_test:
            raise AssertionError(
                "packages/konyak_cli/test/cli_contract_test.dart must remain "
                f"a standalone test library without {forbidden!r}"
            )
    if re.search(r"\bdefine[A-Za-z0-9]+ContractTests\(\);", cli_contract_test):
        raise AssertionError(
            "packages/konyak_cli/test/cli_contract_test.dart must not call "
            "old part-library contract-test registration helpers"
        )


def require_semantic_constructor_value_object_fronts() -> None:
    for expected in [
        (
            "#### PR Gate: I2-P4 Semantic Constructor Primitive Fronts\n\n"
            "status: completed\n"
            "branch: `task/interface-i2-semantic-constructor-fronts`"
        ),
    ]:
        require_contains("docs/todo.md", expected)

    app_settings = "packages/konyak_cli/lib/src/domain/app/app_settings_models.dart"
    require_contains(app_settings, "required DefaultBottlePath defaultBottlePath")
    require_not_contains(app_settings, "required String defaultBottlePath")

    runtime_settings = (
        "packages/konyak_cli/lib/src/domain/bottle/bottle_runtime_settings_models.dart"
    )
    for expected in [
        "EnhancedSyncMode enhancedSync = EnhancedSyncMode.msync",
        "DxvkHudMode dxvkHud = DxvkHudMode.off",
        "WindowsBuildVersion buildVersion = WindowsBuildVersion.none",
        "WindowsDpiScaling dpiScaling = WindowsDpiScaling.standard",
        "BottleRuntimeSettings withBuildVersion(WindowsBuildVersion buildVersion)",
        "BottleRuntimeSettings withDpiScaling(WindowsDpiScaling dpiScaling)",
    ]:
        require_contains(runtime_settings, expected)
    for forbidden in [
        "String enhancedSync =",
        "String dxvkHud =",
        "int buildVersion =",
        "int dpiScaling =",
        "withBuildVersion(int",
        "withDpiScaling(int",
    ]:
        require_not_contains(runtime_settings, forbidden)

    program_settings = (
        "packages/konyak_cli/lib/src/domain/program/program_settings_models.dart"
    )
    for expected in [
        "ProgramLocale locale = ProgramLocale.empty",
        "ProgramArguments arguments = ProgramArguments.empty",
        "WineDebugChannels additionalWineLoggingChannels = WineDebugChannels.empty",
        "ProgramLogPath logFilePath = ProgramLogPath.empty",
    ]:
        require_contains(program_settings, expected)
    for forbidden in [
        "String locale =",
        "String arguments =",
        "String additionalWineLoggingChannels =",
        "String logFilePath =",
    ]:
        require_not_contains(program_settings, forbidden)

    runtime_validation = (
        "packages/konyak_cli/lib/src/domain/runtime/runtime_validation_models.dart"
    )
    require_contains(runtime_validation, "required RuntimeId runtimeId")
    runtime_validation_text = read_text(runtime_validation)
    runtime_record_start = runtime_validation_text.find(
        "abstract class RuntimeValidationRecord"
    )
    if runtime_record_start == -1:
        raise AssertionError("RuntimeValidationRecord must exist")
    next_freezed = runtime_validation_text.find(
        "@Freezed(",
        runtime_record_start + len("abstract class RuntimeValidationRecord"),
    )
    runtime_record_section = (
        runtime_validation_text[runtime_record_start:]
        if next_freezed == -1
        else runtime_validation_text[runtime_record_start:next_freezed]
    )
    if "required String runtimeId" in runtime_record_section:
        raise AssertionError(
            "RuntimeValidationRecord constructor must not expose primitive runtime ids"
        )

    for relative_path, expected in [
        ("packages/konyak_cli/lib/src/io/app_settings_json.dart", "DefaultBottlePath("),
        ("packages/konyak_cli/lib/src/io/repository_storage_io.dart", "ProgramLocale("),
        (
            "packages/konyak_cli/lib/src/io/repository_storage_io.dart",
            "EnhancedSyncMode(parsedEnhancedSync)",
        ),
        (
            "packages/konyak_cli/lib/src/io/repository_storage_io.dart",
            "WindowsBuildVersion(parsedBuildVersion)",
        ),
        (
            "packages/konyak_cli/lib/src/io/repository_storage_io.dart",
            "WindowsDpiScaling(parsedDpiScaling)",
        ),
        (
            "packages/konyak_cli/lib/src/io/program_registry_parsers.dart",
            "WindowsBuildVersion(buildVersion)",
        ),
        (
            "packages/konyak_cli/lib/src/io/program_registry_parsers.dart",
            "WindowsDpiScaling(dpiScaling)",
        ),
    ]:
        require_contains(relative_path, expected)

    for expected in [
        "? storedSettings.locale",
        ": settings.locale",
        "? storedSettings.arguments",
        ": settings.arguments",
    ]:
        require_contains(
            "packages/konyak_cli/lib/src/cli/cli_program_run_handlers.dart",
            expected,
        )

def require_cli_parser_option_boundaries() -> None:
    for relative_path, forbidden in [
        (
            "packages/konyak_cli/lib/src/cli/cli_runtime_parsers.dart",
            "GptkWineInstallRequest? parseJsonGptkWineInstallRequest",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_runtime_parsers.dart",
            "String? parseJsonOpenUrlCommand",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_runtime_parsers.dart",
            "String? parseJsonRuntimeIdCommand",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_runtime_parsers.dart",
            "MacosWineInstallRequest? parseJsonMacosWineInstallRequest",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_runtime_parsers.dart",
            "LinuxWineInstallRequest? parseJsonLinuxWineInstallRequest",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_runtime_parsers.dart",
            "RuntimeInstallCliOptions? parseRuntimeInstallCliOptions",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_location_parsers.dart",
            "BottleLocationOpenCliRequest? parseJsonBottleLocationOpenCliRequest",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_location_parsers.dart",
            "ProgramLocationOpenCliRequest? parseJsonProgramLocationOpenCliRequest",
        ),
    ]:
        require_not_contains(relative_path, forbidden)

    for relative_path, forbidden in [
        (
            "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart",
            "parseJsonGptkWineInstallRequest(arguments)",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart",
            "parseJsonOpenUrlCommand(arguments)",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart",
            "parseJsonRuntimeIdCommand(",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart",
            "parseJsonMacosWineInstallRequest(arguments)",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart",
            "parseJsonLinuxWineInstallRequest(arguments)",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_injected_runner.dart",
            "parseJsonMacosWineInstallRequest(arguments)",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_injected_runner.dart",
            "parseJsonLinuxWineInstallRequest(arguments)",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_location_winetricks_handlers.dart",
            "parseJsonBottleLocationOpenCliRequest(arguments)",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_location_winetricks_handlers.dart",
            "parseJsonProgramLocationOpenCliRequest(arguments)",
        ),
    ]:
        require_not_contains(relative_path, forbidden)

    for relative_path, expected in [
        (
            "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart",
            "parseJsonGptkWineInstallRequestOption(",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart",
            "parseJsonOpenUrlCommandOption(",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart",
            "parseJsonRuntimeIdCommandOption(",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart",
            "parseJsonMacosWineInstallRequestOption(",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart",
            "parseJsonLinuxWineInstallRequestOption(",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_injected_runner.dart",
            "parseJsonMacosWineInstallRequestOption(",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_injected_runner.dart",
            "parseJsonLinuxWineInstallRequestOption(",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_location_winetricks_handlers.dart",
            "parseJsonBottleLocationOpenCliRequestOption(",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_location_winetricks_handlers.dart",
            "parseJsonProgramLocationOpenCliRequestOption(",
        ),
    ]:
        require_contains(relative_path, expected)


def require_cli_command_dispatch_boundaries() -> None:
    for expected in [
        "sealed class CliCommandMatch",
        "final class CliCommandNotMatched extends CliCommandMatch",
        "final class CliCommandMatched extends CliCommandMatch",
        "typedef CliCommandHandler = CliCommandMatch Function();",
        "CliCommandMatch firstCliCommandMatch(",
        "CliCommandMatch legacyCliCommandMatch(CliResult? result)",
    ]:
        require_contains("packages/konyak_cli/lib/src/cli/cli_commands.dart", expected)

    for unexpected in [
        "typedef CliCommandHandler = CliResult? Function();",
        "CliResult? firstCliResult(",
        "firstCliResult(",
        "final commandResult =",
        "if (commandResult != null)",
    ]:
        require_not_contains(
            "packages/konyak_cli/lib/src/cli/cli_commands.dart",
            unexpected,
        )

    for relative_path, expected in [
        (
            "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart",
            "CliCommandMatch handleRuntimeCommand(",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_location_winetricks_handlers.dart",
            "CliCommandMatch handleLocationCommand(",
        ),
    ]:
        require_contains(relative_path, expected)
        require_contains(relative_path, "return const CliCommandNotMatched();")
        require_not_contains(relative_path, "match<CliResult?>")

    for relative_path, unexpected in [
        (
            "packages/konyak_cli/lib/src/cli/cli_app_runtime_handlers.dart",
            "CliResult? handleRuntimeCommand(",
        ),
        (
            "packages/konyak_cli/lib/src/cli/cli_location_winetricks_handlers.dart",
            "CliResult? handleLocationCommand(",
        ),
    ]:
        require_not_contains(relative_path, unexpected)

    dispatch_test_path = (
        "packages/konyak_cli/test/cli_contract_command_dispatch_test.dart"
    )
    require_contains(
        dispatch_test_path,
        "runtime command dispatch reports matched commands explicitly",
    )
    require_contains(
        dispatch_test_path,
        "runtime command dispatch reports unmatched commands explicitly",
    )
    require_contains(
        dispatch_test_path,
        "location command dispatch reports matched commands explicitly",
    )
    require_contains(
        dispatch_test_path,
        "location command dispatch reports unmatched commands explicitly",
    )

    lint_rule_path = "tools/konyak_lints/lib/konyak_lints.dart"
    for expected in [
        "class KonyakNoNullableCliCommandHandler",
        "konyak_no_nullable_cli_command_handler",
        "'handleRuntimeCommand'",
        "'handleLocationCommand'",
    ]:
        require_contains(lint_rule_path, expected)
    require_contains(
        "tools/konyak_lints/test/konyak_lints_test.dart",
        "konyak_no_nullable_cli_command_handler",
    )
    require_contains(
        "tools/konyak_lints/test/fixtures/invalid/packages/konyak_cli/"
        "lib/src/cli/cli_app_runtime_handlers.dart",
        "CliResult? handleRuntimeCommand",
    )


def require_flutter_dialog_decision_boundaries() -> None:
    require_contains(
        "apps/konyak/lib/src/app/dialogs/dialog_decision.dart",
        "Future<T> showDialogDecision<T extends Object>",
    )
    require_contains(
        "apps/konyak/test/app/dialog_decision_test.dart",
        "returns an explicit dismissed decision when a dialog is closed",
    )

    for relative_path in [
        "apps/konyak/lib/src/app/dialogs/create_bottle_dialog.dart",
        "apps/konyak/lib/src/app/dialogs/bottle_management_dialogs.dart",
        "apps/konyak/lib/src/app/dialogs/pin_program_dialog.dart",
        "apps/konyak/lib/src/app/dialogs/run_program_dialog.dart",
        "apps/konyak/lib/src/app/dialogs/confirmation_decision.dart",
        "apps/konyak/lib/src/app/dialogs/open_executable_dialog.dart",
        "apps/konyak/lib/src/app/dialogs/winetricks_dialog.dart",
        "apps/konyak/lib/src/app/home/sidebar_bottle_item.dart",
        "apps/konyak/lib/src/app/programs/pinned_program_context_menu.dart",
    ]:
        require_not_contains(relative_path, "DecisionFromNullable")
        require_not_contains(relative_path, "Decision? decision")
        require_not_contains(relative_path, "ContextMenuAction? action")

    require_contains(
        "apps/konyak/lib/src/app/home/sidebar_bottle_item.dart",
        "sealed class BottleContextMenuDecision",
    )
    require_contains(
        "apps/konyak/test/app/sidebar_bottle_item_test.dart",
        "models bottle context menu decisions explicitly",
    )
    require_not_contains(
        "apps/konyak/lib/src/app/home/sidebar_bottle_item.dart",
        "selectedAction == null",
    )

    for relative_path, expected in [
        (
            "apps/konyak/lib/src/home_loader/home_loader_bottles.dart",
            "showDialogDecision<CreateBottleDecision>",
        ),
        (
            "apps/konyak/lib/src/home_loader/home_loader_bottles.dart",
            "showDialogDecision<DeleteBottleDecision>",
        ),
        (
            "apps/konyak/lib/src/home_loader/home_loader_bottles.dart",
            "showDialogDecision<RenameBottleDecision>",
        ),
        (
            "apps/konyak/lib/src/home_loader/home_loader_bottles.dart",
            "showDialogDecision<MoveBottleDecision>",
        ),
        (
            "apps/konyak/lib/src/home_loader/home_loader_pinned_programs.dart",
            "showDialogDecision<PinProgramDecision>",
        ),
        (
            "apps/konyak/lib/src/home_loader/home_loader_pinned_programs.dart",
            "showDialogDecision<RenamePinnedProgramDecision>",
        ),
        (
            "apps/konyak/lib/src/home_loader/home_loader_programs.dart",
            "showDialogDecision<RunProgramDialogDecision>",
        ),
        (
            "apps/konyak/lib/src/home_loader/home_loader_executables.dart",
            "showDialogDecision<OpenExecutableDecision>",
        ),
        (
            "apps/konyak/lib/src/home_loader/home_loader_winetricks.dart",
            "showDialogDecision<WinetricksVerbDecision>",
        ),
        (
            "apps/konyak/lib/src/home_loader/home_loader_runtimes.dart",
            "showDialogDecision<ConfirmationDecision>",
        ),
        (
            "apps/konyak/lib/src/app/dialogs/app_settings_dialog.dart",
            "showDialogDecision<ConfirmationDecision>",
        ),
    ]:
        require_contains(relative_path, expected)

    for relative_path in [
        "apps/konyak/lib/src/home_loader/home_loader_bottles.dart",
        "apps/konyak/lib/src/home_loader/home_loader_pinned_programs.dart",
        "apps/konyak/lib/src/home_loader/home_loader_programs.dart",
        "apps/konyak/lib/src/home_loader/home_loader_executables.dart",
        "apps/konyak/lib/src/home_loader/home_loader_winetricks.dart",
        "apps/konyak/lib/src/home_loader/home_loader_runtimes.dart",
        "apps/konyak/lib/src/app/dialogs/app_settings_dialog.dart",
    ]:
        require_not_contains(relative_path, "DecisionFromNullable")


def require_flutter_update_optional_field_boundaries() -> None:
    optional_fields = "apps/konyak/lib/src/cli/cli_optional_fields.dart"
    for expected in [
        "sealed class CliOptionalString",
        "const factory CliOptionalString.absent()",
        "const factory CliOptionalString.explicitNull()",
        "const factory CliOptionalString.present(String value)",
    ]:
        require_contains(optional_fields, expected)

    update_summary = "apps/konyak/lib/src/updates/update_check_summary.dart"
    for expected in [
        "final CliOptionalString currentVersion;",
        "final CliOptionalString latestVersion;",
        "final CliOptionalString versionUrl;",
        "final CliOptionalString archiveUrl;",
        "final CliOptionalString installedVersion;",
        "final CliOptionalString installPath;",
    ]:
        require_contains(update_summary, expected)
    for forbidden in [
        "final String? currentVersion;",
        "final String? latestVersion;",
        "final String? versionUrl;",
        "final String? archiveUrl;",
        "final String? installedVersion;",
        "final String? installPath;",
    ]:
        require_not_contains(update_summary, forbidden)

    update_parser = "apps/konyak/lib/src/cli/konyak_cli_update_payload_parsers.dart"
    for expected in [
        "CliOptionalStringParseResult parseCliOptionalStringField",
        "payload.containsKey(key)",
        "parseCliOptionalStringField(",
        "ParsedCliOptionalString(value: final currentVersion)",
        "ParsedCliOptionalString(value: final latestVersion)",
        "ParsedCliOptionalString(value: final installedVersion)",
    ]:
        require_contains(update_parser, expected)
    for forbidden in [
        "currentVersion as String?",
        "latestVersion as String?",
        "versionUrl as String?",
        "archiveUrl as String?",
        "installedVersion as String?",
        "installPath as String?",
        "isOptionalString(currentVersion)",
        "isOptionalString(latestVersion)",
        "isOptionalString(installedVersion)",
    ]:
        require_not_contains(update_parser, forbidden)

    update_tests = "apps/konyak/test/cli/konyak_cli_update_payload_parsers_test.dart"
    for expected in [
        "models absent and explicit null update check fields distinctly",
        "models absent and explicit null update install fields distinctly",
        "const CliOptionalString.absent()",
        "const CliOptionalString.explicitNull()",
        "const CliOptionalString.present('1.1.0')",
    ]:
        require_contains(update_tests, expected)

    for relative_path, forbidden in [
        ("apps/konyak/lib/src/home_loader/home_loader_runtimes.dart", "latestVersion == null"),
        ("apps/konyak/lib/src/app/utils/update_labels.dart", "??"),
    ]:
        require_not_contains(relative_path, forbidden)


def require_refactoring_governance_allowance_cleanup() -> None:
    lint_rules = "tools/konyak_lints/lib/konyak_lints.dart"
    require_not_contains(lint_rules, "'apps/konyak/lib/src/updates/',")
    require_contains(
        lint_rules,
        "'apps/konyak/lib/src/cli/konyak_cli_update_payload_parsers.dart'",
    )

    require_not_contains(
        "apps/konyak/lib/src/updates/update_check_summary.dart",
        "String?",
    )
    require_contains(
        "tools/konyak_lints/test/konyak_lints_test.dart",
        "invalid Flutter fixture reports app-facing nullable violations",
    )
    require_contains(
        "tools/konyak_lints/test/fixtures/invalid/apps/konyak/"
        "lib/src/updates/update_check_summary.dart",
        "final String? latestVersion;",
    )
    require_contains(
        "docs/todo.md",
        "status: completed\nbranch: `task/interface-i1-governance-allowances`",
    )


def require_konyak_cli_public_exports() -> None:
    lines = read_text("packages/konyak_cli/lib/konyak_cli.dart").splitlines()
    if lines != KONYAK_CLI_PUBLIC_EXPORT_LINES:
        expected = "\n".join(KONYAK_CLI_PUBLIC_EXPORT_LINES)
        raise AssertionError(
            "packages/konyak_cli/lib/konyak_cli.dart must expose only the "
            "approved CLI facade and domain contract exports:\n"
            f"{expected}"
        )


def require_konyak_cli_public_facade_signature() -> None:
    require_exact(
        "packages/konyak_cli/lib/src/cli/cli_facade.dart",
        """import 'cli_default_runner.dart';
import 'cli_result_model.dart';

CliResult runCli(List<String> arguments) {
  return runCliWithDefaultIo(arguments);
}

Future<CliResult> runCliStreaming(List<String> arguments) {
  return runCliStreamingWithDefaultIo(arguments);
}
""",
    )


def require_no_repository_dartio_defaults() -> None:
    repository_root = ROOT / "packages/konyak_cli/lib/src/repository"
    if not repository_root.exists():
        return

    for path in sorted(repository_root.rglob("*.dart")):
        text = path.read_text(encoding="utf-8")
        if "DartIoProgramMetadataExtractor()" in text or "DartIoBottleProgramRepository(" in text:
            relative_path = path.relative_to(ROOT)
            raise AssertionError(
                f"{relative_path} must receive I/O implementations explicitly from composition roots"
            )


def require_no_cli_state_errors() -> None:
    cli_root = ROOT / "packages/konyak_cli/lib/src"
    if not cli_root.exists():
        return

    for path in sorted(cli_root.rglob("*.dart")):
        text = path.read_text(encoding="utf-8")
        if "StateError(" in text or "throw StateError" in text:
            relative_path = path.relative_to(ROOT)
            raise AssertionError(
                f"{relative_path} must model expected absence or failure with Option/Either/result variants"
            )


def require_cli_injected_runner_has_no_dartio_defaults() -> None:
    text = read_text("packages/konyak_cli/lib/src/cli/cli_injected_runner.dart")
    for unexpected in ["DartIo", "currentProgramRunPlanner", "../io/"]:
        if unexpected in text:
            raise AssertionError(
                "packages/konyak_cli/lib/src/cli/cli_injected_runner.dart "
                f"must not contain default I/O composition: {unexpected}"
            )


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


def require_custom_lint_rules() -> None:
    require_missing("scripts/verify_domain_reassignment.dart")
    require_contains("tools/konyak_lints/pubspec.yaml", "custom_lint_builder:")
    require_contains("tools/konyak_lints/lib/konyak_lints.dart", "createPlugin()")
    require_contains("justfile", "flutter-custom-lint")
    require_contains("justfile", "cli-custom-lint")
    require_contains("justfile", "konyak-lints-analyze")
    require_contains("justfile", "konyak-lints-format-check")
    require_contains("justfile", "konyak-lints-test")

    lint_consumers = [
        ("apps/konyak/pubspec.yaml", "apps/konyak/analysis_options.yaml"),
        ("packages/konyak_cli/pubspec.yaml", "packages/konyak_cli/analysis_options.yaml"),
    ]
    for pubspec_path, options_path in lint_consumers:
        require_contains(pubspec_path, "custom_lint:")
        require_contains(pubspec_path, "konyak_lints:")
        require_contains(options_path, "plugins:")
        require_contains(options_path, "- custom_lint")
        require_contains(options_path, "custom_lint:")
        for rule in CUSTOM_LINT_RULES:
            require_contains(options_path, rule)
            require_contains("tools/konyak_lints/lib/konyak_lints.dart", rule)


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
    for path in sorted((ROOT / "packages/konyak_cli/lib/src").rglob("*.dart")):
        relative_path = str(path.relative_to(ROOT))
        if relative_path.startswith("packages/konyak_cli/lib/src/io/"):
            continue

        text = path.read_text(encoding="utf-8")
        for pattern in io_patterns:
            if pattern == "File(":
                match = re.search(r"(?<![A-Za-z0-9_])File\(", text)
            elif pattern == "Directory(":
                match = re.search(r"(?<![A-Za-z0-9_])Directory\(", text)
            else:
                match = re.search(re.escape(pattern), text)
            if match is not None:
                raise AssertionError(
                    f"{relative_path} must not contain I/O pattern outside src/io: {pattern}"
                )


def require_plist_key(relative_path: str, key: str, expected: object) -> None:
    with (ROOT / relative_path).open("rb") as file:
        plist = plistlib.load(file)

    actual = plist.get(key)
    if actual != expected:
        raise AssertionError(f"{relative_path} must set {key} to {expected!r}, got {actual!r}")


def require_app_version_sources_match() -> None:
    pubspec = read_text("apps/konyak/pubspec.yaml")
    model_constants = read_text("packages/konyak_cli/lib/src/shared/model_constants.dart")
    pubspec_match = re.search(
        r"(?m)^version:[ \t]*([0-9]+\.[0-9]+\.[0-9]+)(?:\+[0-9]+)?[ \t]*$",
        pubspec,
    )
    if pubspec_match is None:
        raise AssertionError("apps/konyak/pubspec.yaml must declare a semantic app version")

    cli_match = re.search(
        r"const konyakAppVersion = String\.fromEnvironment\(\s*"
        r"'KONYAK_APP_VERSION',\s*defaultValue: '([0-9]+\.[0-9]+\.[0-9]+)',\s*\);",
        model_constants,
        flags=re.MULTILINE,
    )
    if cli_match is None:
        raise AssertionError(
            "packages/konyak_cli/lib/src/shared/model_constants.dart must declare "
            "konyakAppVersion with a KONYAK_APP_VERSION compile-time default"
        )

    app_version = pubspec_match.group(1)
    cli_version = cli_match.group(1)
    if app_version != cli_version:
        raise AssertionError(
            "Flutter app version and CLI app update version must match: "
            f"pubspec={app_version}, konyakAppVersion={cli_version}"
        )


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
        "packages/konyak_cli/lib/src/domain/bottle/bottle_models.dart",
        "package:fast_immutable_collections/fast_immutable_collections.dart",
    )
    require_contains("packages/konyak_cli/lib/src/io/io_result.dart", "package:fpdart/fpdart.dart")
    require_missing(REMOVED_CLI_BACKEND)
    require_no_handwritten_parts()
    require_no_transitional_part_paste_markers()
    require_production_file_line_limits()
    require_flutter_home_contract_boundaries()
    require_no_repository_dartio_defaults()
    require_no_files_under("packages/konyak_cli/lib/src", "*.dart")
    require_io_implementation_boundaries()
    require_external_payload_parser_boundaries()
    require_custom_lint_rules()

    for expected in [
        "typedef IoResult<T> = Either<String, T>",
        "Either<String, T> ioResult<T>",
        "Right<String, T>",
        "Left<String, T>",
    ]:
        require_contains("packages/konyak_cli/lib/src/io/io_result.dart", expected)

    require_not_contains(
        "packages/konyak_cli/lib/src/repository/repository_interfaces.dart",
        "IoResult<BottleRecord?> findBottle",
    )
    bottle_model_text = read_text(
        "packages/konyak_cli/lib/src/domain/bottle/bottle_models.dart"
    )
    for expected_options in [
        ["final BottleId id;", "required BottleId id,"],
        ["final BottleName name;", "required BottleName name,"],
        ["final BottlePath path;", "required BottlePath path,"],
        [
            "final WindowsVersion windowsVersion;",
            "required WindowsVersion windowsVersion,",
        ],
        [
            "final IList<PinnedProgramRecord> pinnedPrograms;",
            "required IList<PinnedProgramRecord> pinnedPrograms,",
        ],
        ["final ProgramName name;", "required ProgramName name,"],
        ["final ProgramPath path;", "required ProgramPath path,"],
        [
            "final Option<ProgramIconPath> iconPath;",
            "required Option<ProgramIconPath> iconPath,",
        ],
        ["Option<String> iconPath = const Option.none()"],
        ["iconPath.map("],
    ]:
        if not any(expected in bottle_model_text for expected in expected_options):
            raise AssertionError(
                "packages/konyak_cli/lib/src/domain/bottle/bottle_models.dart "
                f"must contain one of: {expected_options}"
            )
    require_contains(
        "packages/konyak_cli/lib/src/domain/shared/domain_value_objects.dart",
        "throw ArgumentError.value",
    )
    require_contains(
        "packages/konyak_cli/lib/src/domain/shared/domain_helpers.dart",
        "throw ArgumentError.value",
    )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/bottle/bottle_models.dart",
        "final String? iconPath;",
    )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/bottle/bottle_models.dart",
        "copyWith: false",
    )
    for unexpected in [
        "BottleRecord withIdentity(",
        "BottleRecord withPath(",
        "BottleRecord withWindowsVersion(",
        "BottleRecord withRuntimeSettings(",
        "BottleRecord withPinnedPrograms(",
        "PinnedProgramRecord withName(",
        "PinnedProgramRecord withIconPath(",
        "BottleRecord withIdentity({\n    required String id,",
        "BottleRecord withPath(String path)",
        "BottleRecord withWindowsVersion(String windowsVersion)",
        "PinnedProgramRecord withName(String name)",
        "PinnedProgramRecord withIconPath(Option<String> iconPath)",
    ]:
        require_not_contains(
            "packages/konyak_cli/lib/src/domain/bottle/bottle_models.dart",
            unexpected,
        )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/bottle/bottle_models.dart",
        "final List<PinnedProgramRecord> pinnedPrograms;",
    )
    program_settings_models = read_text(
        "packages/konyak_cli/lib/src/domain/program/program_settings_models.dart"
    )
    if (
        "final ProgramEnvironmentOverrides environment;"
        not in program_settings_models
        and "required ProgramEnvironmentOverrides environment,"
        not in program_settings_models
    ):
        raise AssertionError(
            "ProgramSettingsRecord must expose ProgramEnvironmentOverrides "
            "instead of primitive or map-backed environment fields"
        )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/program/program_settings_models.dart",
        "final IMap<String, String> environment;",
    )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/program/program_settings_models.dart",
        "final Map<String, String> environment;",
    )
    for expected in [
        "required ProgramId id,",
        "required ProgramName name,",
        "required ProgramPath path,",
        "required ProgramSource source,",
        "required BottleId bottleId,",
        "required WineProcessId processId,",
        "required ProgramExecutable executable,",
        "Option<ProgramPath> hostPath = const Option.none(),",
        "Option<ProgramArchitecture> architecture = const Option.none(),",
        "Option<ProgramFileDescription> fileDescription = const Option.none(),",
        "Option<ProgramProductName> productName = const Option.none(),",
        "Option<ProgramCompanyName> companyName = const Option.none(),",
        "Option<ProgramFileVersion> fileVersion = const Option.none(),",
        "Option<ProgramProductVersion> productVersion = const Option.none(),",
        "Option<ProgramIconPath> iconPath = const Option.none(),",
        "required WinetricksVerbId id,",
        "required WinetricksVerbName name,",
        "required WinetricksVerbDescription description,",
        "required WinetricksCategoryId id,",
        "required WinetricksCategoryName name,",
        "required Option<ProgramMetadataRecord> metadata,",
        "required Option<ProgramPath> hostPath,",
        "Option<ProgramMetadataRecord> extract({",
        "required Option<ProgramArchitecture> architecture,",
        "required Option<ProgramFileDescription> fileDescription,",
        "required Option<ProgramProductName> productName,",
        "required Option<ProgramCompanyName> companyName,",
        "required Option<ProgramFileVersion> fileVersion,",
        "required Option<ProgramProductVersion> productVersion,",
        "required Option<ProgramIconPath> iconPath,",
    ]:
        require_contains("packages/konyak_cli/lib/src/domain/program/program_catalog_models.dart", expected)
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/program/program_catalog_models.dart",
        "final String? iconPath;",
    )
    for unexpected in [
        "required String id,",
        "required String name,",
        "required String path,",
        "required String source,",
        "required String bottleId,",
        "required String processId,",
        "required String executable,",
        "Option<String> hostPath = const Option.none(),",
        "Option<String> architecture = const Option.none(),",
        "Option<String> fileDescription = const Option.none(),",
        "Option<String> productName = const Option.none(),",
        "Option<String> companyName = const Option.none(),",
        "Option<String> fileVersion = const Option.none(),",
        "Option<String> productVersion = const Option.none(),",
        "Option<String> iconPath = const Option.none(),",
    ]:
        require_not_contains(
            "packages/konyak_cli/lib/src/domain/program/program_catalog_models.dart",
            unexpected,
        )
    for unexpected in [
        "required String id,",
        "required String name,",
        "required String description,",
    ]:
        require_not_contains(
            "packages/konyak_cli/lib/src/domain/program/program_catalog_models.dart",
            unexpected,
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
        "required Option<RuntimeVersion> currentVersion,",
        "required Option<RuntimeVersion> latestVersion,",
        "required Option<RuntimeVersionUrl> versionUrl,",
        "required Option<RuntimeArchiveUrl> archiveUrl,",
        "required Option<RuntimeSourceManifestUrl> sourceManifestUrl,",
        "required Option<RuntimeSourceManifestSignatureUrl>",
        "required Option<AppVersion> currentVersion,",
        "required Option<ReleaseVersion> latestVersion,",
        "required Option<AppArchiveUrl> archiveUrl,",
        "required Option<AppArchiveSha256> archiveSha256,",
        "required Option<AppInstallPath> installPath,",
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
        "sealed class RuntimeInstallRequestOperation",
        "with _$RuntimeInstallRequestOperation",
        "factory RuntimeInstallRequestOperation.fullInstall",
        "factory RuntimeInstallRequestOperation.repair",
        "factory RuntimeInstallRequestOperation.componentInstall",
        "factory RuntimeInstallRequestOperation.updateInstall",
        ") = RuntimeFullInstallOperation;",
        ") = RuntimeRepairOperation;",
        ") = RuntimeComponentInstallOperation;",
        ") = RuntimeUpdateInstallOperation;",
        "required RuntimeInstallSource installSource",
        "required bool force",
        "sealed class RuntimeInstallSource with _$RuntimeInstallSource",
        "factory RuntimeInstallSource.configuredArchive",
        "factory RuntimeInstallSource.localArchive",
        "factory RuntimeInstallSource.remoteArchive",
        "factory RuntimeInstallSource.sourceManifest",
        "Iterable<RuntimeArchivePath> componentArchivePaths =",
        "required RuntimeArchivePath archivePath,",
        "required RuntimeArchiveUrl archiveUrl,",
        "required RuntimeSourceManifestUrl sourceManifest,",
        "RuntimeSourceManifestSignature runtimeSourceManifestSignature(\n  Option<RuntimeSourceManifestSignatureUrl> value,",
        ") = RuntimeConfiguredArchiveSource;",
        ") = RuntimeLocalArchiveSource;",
        ") = RuntimeRemoteArchiveSource;",
        ") = RuntimeSourceManifestInstallSource;",
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
        "required String archivePath,",
        "required String archiveUrl,",
        "required String sourceManifest,",
        "Iterable<String> paths,",
        "RuntimeSourceManifestSignature runtimeSourceManifestSignature(\n  Option<String> value,",
    ]:
        require_not_contains(
            "packages/konyak_cli/lib/src/domain/runtime/runtime_install_operation_models.dart",
            forbidden,
        )
    for expected in [
        "required Option<RuntimeSourceManifestUrl> configuredSourceManifest,",
        "Option<RuntimeSourceManifestSignatureUrl>",
    ]:
        require_contains(
            "packages/konyak_cli/lib/src/domain/runtime/runtime_install_plans.dart",
            expected,
        )
    for forbidden in [
        "required Option<String> configuredSourceManifest",
        "required Option<String> configuredSourceManifestSignature",
    ]:
        require_not_contains(
            "packages/konyak_cli/lib/src/domain/runtime/runtime_install_plans.dart",
            forbidden,
        )
    for expected_options in [
        ["Option<RuntimeSourceManifestUrl> runtimeSourceManifestForPlatform({"],
        [
            "Option<RuntimeSourceManifestSignatureUrl> runtimeSourceManifestSignatureForPlatform({",
            "Option<RuntimeSourceManifestSignatureUrl>\nruntimeSourceManifestSignatureForPlatform({",
        ],
    ]:
        if not any(
            expected
            in read_text(
                "packages/konyak_cli/lib/src/domain/runtime/runtime_platform_support.dart"
            )
            for expected in expected_options
        ):
            raise AssertionError(
                "runtime platform support must expose typed source manifest "
                f"helpers: {expected_options[0]}"
            )
    runtime_package_installation_text = read_text(
        "packages/konyak_cli/lib/src/domain/runtime/runtime_package_installation.dart"
    )
    for expected in [
        "required RuntimeArchivePath archivePath,",
        "required Option<RuntimeArchiveChecksumValue> archiveSha256,",
        "required Iterable<RuntimeArchivePath> componentArchivePaths,",
        "required RuntimeRootPath runtimeRoot,",
        "required RuntimeRelativePath requiredExecutableRelativePath,",
        "required RuntimeComponentPath expectedExecutablePath,",
        "Iterable<RuntimeRelativePath> preserveExistingRuntimeSkipRelativePaths",
        "required IList<RuntimeRelativePath>\n    preserveExistingRuntimeSkipRelativePaths,",
    ]:
        if expected not in runtime_package_installation_text:
            raise AssertionError(
                "RuntimePackageInstallRequest must expose typed package "
                f"install values: {expected}"
            )

    for relative_path, expected_terms in {
        "packages/konyak_cli/lib/src/domain/runtime/runtime_source_bundle_models.dart": [
            "required RuntimeArchivePath wineArchivePath,",
            "required Iterable<RuntimeArchivePath> componentArchivePaths,",
            "required IList<RuntimeArchivePath> componentArchivePaths,",
        ],
        "packages/konyak_cli/lib/src/domain/runtime/runtime_source_archive_planning.dart": [
            "required RuntimeArchivePath archivePath,",
            "archivePath: RuntimeArchivePath(",
        ],
    }.items():
        source = read_text(relative_path)
        for expected in expected_terms:
            if expected not in source:
                raise AssertionError(
                    "Runtime source archive planning must expose typed "
                    f"archive paths: {relative_path} {expected}"
                )

    for relative_path, forbidden_terms in {
        "packages/konyak_cli/lib/src/domain/runtime/runtime_source_bundle_models.dart": [
            "required String wineArchivePath,",
            "required Iterable<String> componentArchivePaths,",
        ],
        "packages/konyak_cli/lib/src/domain/runtime/runtime_source_archive_planning.dart": [
            "required String archivePath,",
        ],
    }.items():
        source = read_text(relative_path)
        for forbidden in forbidden_terms:
            if forbidden in source:
                raise AssertionError(
                    "Runtime source archive planning must not expose "
                    f"primitive archive paths: {relative_path} {forbidden}"
                )

    if not any(
        expected in runtime_package_installation_text
        for expected in [
            "final Option<RuntimeArchiveChecksumValue> archiveSha256;",
            "required Option<RuntimeArchiveChecksumValue> archiveSha256,",
        ]
    ):
        raise AssertionError(
            "packages/konyak_cli/lib/src/domain/runtime/runtime_package_installation.dart "
            "must contain a typed archiveSha256 field or _validated "
            "constructor parameter"
        )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/runtime/runtime_package_installation.dart",
        "final String? archiveSha256;",
    )
    for forbidden in [
        "required String archivePath,",
        "required Option<String> archiveSha256,",
        "required Iterable<String> componentArchivePaths,",
        "required String runtimeRoot,",
        "required List<String> requiredExecutableRelativePath,",
        "required String expectedExecutablePath,",
        "List<List<String>> preserveExistingRuntimeSkipRelativePaths",
    ]:
        if forbidden in runtime_package_installation_text:
            raise AssertionError(
                "RuntimePackageInstallRequest must not expose primitive "
                f"package install values: {forbidden}"
            )
    runtime_models_text = read_text(
        "packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart"
    )
    if not any(
        expected in runtime_models_text
        for expected in [
            "final Option<RuntimeVersion> version;",
            "required Option<RuntimeVersion> version,",
        ]
    ):
        raise AssertionError(
            "packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart "
            "must contain a typed RuntimeStackComponent version field or "
            "_validated constructor parameter"
        )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart",
        "final String? version;",
    )
    for field_type, field_name in [
        ("Option<RuntimeDistributionKind>", "distributionKind"),
        ("Option<bool>", "isInstalled"),
        ("Option<RuntimeArchiveUrl>", "archiveUrl"),
        ("Option<RuntimeVersionUrl>", "versionUrl"),
        ("Option<RuntimeComponentPath>", "applicationSupportPath"),
        ("Option<RuntimeComponentPath>", "libraryPath"),
        ("Option<RuntimeComponentPath>", "executablePath"),
        ("Option<RuntimeStack>", "stack"),
    ]:
        if not any(
            expected in runtime_models_text
            for expected in [
                f"final {field_type} {field_name};",
                f"required {field_type} {field_name},",
            ]
        ):
            raise AssertionError(
                "packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart "
                f"must contain a typed {field_name} field or "
                "_validated constructor parameter"
            )
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

    result_wrapped_repository_operation_paths = [
        "packages/konyak_cli/lib/src/repository/file_bottle_repository_mutation_operations.dart",
        "packages/konyak_cli/lib/src/repository/file_bottle_repository_program_operations.dart",
    ]
    for relative_path in result_wrapped_repository_operation_paths:
        require_contains(relative_path, "ioResult(")
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

    program_mutation_text = read_text(
        "packages/konyak_cli/lib/src/domain/program/program_mutation_models.dart"
    )
    for expected_options in [
        ["class ProgramPinFailed", "ProgramPinResult.failed"],
        ["class ProgramUpdateFailed", "ProgramUpdateResult.failed"],
        ["class ProgramSettingsReadFailed", "ProgramSettingsReadResult.failed"],
        [
            "class ProgramSettingsUpdateFailed",
            "ProgramSettingsUpdateResult.failed",
        ],
    ]:
        if not any(expected in program_mutation_text for expected in expected_options):
            raise AssertionError(
                "packages/konyak_cli/lib/src/domain/program/"
                "program_mutation_models.dart must contain one of: "
                f"{expected_options}"
            )

    require_contains(
        "packages/konyak_cli/lib/src/cli/cli_injected_runner.dart",
        "code: 'bottleRepositoryError'",
    )


def require_external_payload_parser_boundaries() -> None:
    external_payload_helper_markers = [
        "objectMap(",
        "stringMap(",
        "processOutputToString(",
        "readUint16(",
        "readUint32(",
        "nullableOption(",
        "readUint16Option(",
        "readUint32Option(",
        "nullTerminatedAsciiString",
        "nullTerminatedUtf16LeString",
        "nullByteOffset(",
    ]

    for unexpected in [
        *external_payload_helper_markers,
        "Object?",
        "ProcessResult",
        "Uint8List",
        "Map<String, dynamic>",
    ]:
        require_not_contains("packages/konyak_cli/lib/src/shared/model_constants.dart", unexpected)

    for relative_directory in [
        "packages/konyak_cli/lib/src/domain",
        "packages/konyak_cli/lib/src/platform",
        "packages/konyak_cli/lib/src/repository",
        "packages/konyak_cli/lib/src/storage",
    ]:
        for unexpected in external_payload_helper_markers:
            require_not_contains_under(relative_directory, "*.dart", unexpected)

    for relative_path in [
        "packages/konyak_cli/lib/src/domain/process/wine_process_metadata.dart",
        "packages/konyak_cli/lib/src/domain/program/external_program_launch_records.dart",
        "packages/konyak_cli/lib/src/domain/program/pe_program_icons.dart",
        "packages/konyak_cli/lib/src/domain/program/pe_program_image.dart",
        "packages/konyak_cli/lib/src/domain/program/pe_program_metadata.dart",
        "packages/konyak_cli/lib/src/domain/program/pe_program_versions.dart",
        "packages/konyak_cli/lib/src/domain/program/program_registry_parsers.dart",
        "packages/konyak_cli/lib/src/domain/program/program_shortcut_metadata.dart",
        "packages/konyak_cli/lib/src/domain/program/program_winetricks_support.dart",
    ]:
        require_missing(relative_path)

    for expected in external_payload_helper_markers:
        require_contains(
            "packages/konyak_cli/lib/src/io/external_payload_helpers.dart",
            expected,
        )

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
        "apps/konyak/lib/src/home_loader/home_loader_platform_helpers.dart",
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

    for expected in [
        "class FileAppSettingsRepository",
        "macosPinnedLauncherManifestFileName",
        "String resolveDataHome(HostEnvironment environment)",
        "ProgramSettingsRecord readProgramSettingsJson(String path)",
        "RuntimeReleaseMetadata(",
        "Option<String> runtimeReleaseSourceManifestUrl(",
        "RuntimeSourceManifest(",
    ]:
        require_any_contains(
            [
                "packages/konyak_cli/lib/src/io/app_settings_repositories.dart",
                "packages/konyak_cli/lib/src/io/macos_pinned_launchers.dart",
                "packages/konyak_cli/lib/src/storage/storage_paths.dart",
                "packages/konyak_cli/lib/src/io/repository_storage_io.dart",
                "packages/konyak_cli/lib/src/io/runtime_release_metadata.dart",
                "packages/konyak_cli/lib/src/io/runtime_release_metadata_assets.dart",
                "packages/konyak_cli/lib/src/io/runtime_release_metadata_source_manifests.dart",
                "packages/konyak_cli/lib/src/io/runtime_source_manifest_support.dart",
            ],
            expected,
        )


def require_typed_domain_string_maps() -> None:
    domain_root = ROOT / "packages/konyak_cli/lib/src/domain"
    if not domain_root.exists():
        return

    allowed_raw_string_map_paths = {
        "packages/konyak_cli/lib/src/domain/program/program_run_environment.dart",
        "packages/konyak_cli/lib/src/domain/runtime/host_environment.dart",
        "packages/konyak_cli/lib/src/domain/runtime/runtime_component_versions.dart",
    }
    for path in sorted(domain_root.rglob("*.dart")):
        relative_path = str(path.relative_to(ROOT))
        if relative_path in allowed_raw_string_map_paths:
            continue

        text = path.read_text(encoding="utf-8")
        for unexpected in [
            "Map<String, String>",
            "Map<String,String>",
        ]:
            if unexpected in text:
                raise AssertionError(
                    f"{relative_path} must use a typed value object instead of {unexpected}"
                )

    for relative_path, expected in [
        (
            "packages/konyak_cli/lib/src/domain/program/program_run_environment.dart",
            "final class ProgramEnvironmentOverrides",
        ),
        (
            "packages/konyak_cli/lib/src/domain/program/program_run_environment.dart",
            "final class ProgramRunEnvironment",
        ),
        (
            "packages/konyak_cli/lib/src/domain/runtime/host_environment.dart",
            "final class HostEnvironment",
        ),
        (
            "packages/konyak_cli/lib/src/domain/runtime/runtime_component_versions.dart",
            "final class RuntimeComponentVersions",
        ),
    ]:
        require_contains(relative_path, expected)

    program_run_environment = read_text(
        "packages/konyak_cli/lib/src/domain/program/program_run_environment.dart"
    )
    for expected in [
        "ProgramEnvironmentOverrides add(\n    ProgramEnvironmentVariableName name,\n    ProgramEnvironmentVariableValue value,",
        "ProgramRunEnvironment add(\n    ProgramEnvironmentVariableName name,\n    ProgramEnvironmentVariableValue value,",
    ]:
        if expected not in program_run_environment:
            raise AssertionError(
                "ProgramRunEnvironment and overrides must add typed "
                f"environment variables: {expected}"
            )
    for forbidden in [
        "ProgramEnvironmentOverrides add(String name, String value)",
        "ProgramRunEnvironment add(String name, String value)",
    ]:
        if forbidden in program_run_environment:
            raise AssertionError(
                "ProgramRunEnvironment and overrides must not add raw "
                f"environment variables: {forbidden}"
            )

    component_versions_path = (
        "packages/konyak_cli/lib/src/domain/runtime/runtime_component_versions.dart"
    )
    component_versions = read_text(component_versions_path)
    expected_component_version_terms = [
        "RuntimeComponentVersions add(\n    RuntimeComponentId componentId,\n    RuntimeVersion version,",
        "Option<RuntimeVersion> operator [](RuntimeComponentId componentId)",
        "_versions.add(componentId, version)",
    ]
    for expected in expected_component_version_terms:
        if expected not in component_versions:
            raise AssertionError(
                "RuntimeComponentVersions must keep mutation and lookup "
                f"helpers typed: {expected}"
            )

    forbidden_component_version_terms = [
        "RuntimeComponentVersions add(String componentId, String version)",
        "Option<String> operator [](String componentId)",
    ]
    for forbidden in forbidden_component_version_terms:
        if forbidden in component_versions:
            raise AssertionError(
                "RuntimeComponentVersions helpers must not expose primitive "
                f"component versions: {forbidden}"
            )


def require_runtime_ssot_rules() -> None:
    for unexpected in [
        "WinetricksScriptInstaller",
        "DartIoWinetricksScriptInstaller",
        "WinetricksScriptInstallResult",
        "winetricksScriptUrl",
        "raw.githubusercontent.com/Winetricks/winetricks/master",
    ]:
        require_not_contains("packages/konyak_cli/lib/konyak_cli.dart", unexpected)
        require_not_contains_under("packages/konyak_cli/lib/src", "*.dart", unexpected)

    for unexpected in [
        "prepare_winetricks_component",
        "KONYAK_DEV_WINETRICKS_SCRIPT_URL",
        "KONYAK_DEV_DXVK_ARCHIVE_URL",
        "KONYAK_DEV_MACOS_RUNTIME_SOURCE_MODE=local",
        "Components/winetricks",
    ]:
        require_not_contains("scripts/prepare_macos_dev_runtime_stack.zsh", unexpected)

    for unexpected in [
        "prepare_winetricks_component",
        "prepare_wine_mono_component",
        "prepare_dxvk_component",
        "prepare_vkd3d_proton_component",
        "DEFAULT_WINETRICKS_SCRIPT_URL",
        "DEFAULT_WINE_MONO_ARCHIVE_URL",
        "DEFAULT_DXVK_ARCHIVE_URL",
        "DEFAULT_VKD3D_PROTON_ARCHIVE_URL",
        "KONYAK_DEV_LINUX_WINETRICKS_SCRIPT_URL",
        "KONYAK_DEV_LINUX_DXVK_UPSTREAM_ARCHIVE_URL",
        "KONYAK_DEV_LINUX_VKD3D_PROTON_UPSTREAM_ARCHIVE_URL",
        "raw.githubusercontent.com/Winetricks/winetricks",
    ]:
        require_not_contains("scripts/prepare_linux_dev_runtime_source.zsh", unexpected)

    for unexpected in [
        "darwinDevelopmentRuntimeSourcePackages",
        "KONYAK_DEV_NIX_GSTREAMER_PATH",
    ]:
        require_not_contains("flake.nix", unexpected)

    for unexpected in [
        "macos-vulkan-wine-smoke:",
        "linux-vulkan-wine-smoke:",
    ]:
        require_not_contains("justfile", unexpected)
    for expected in [
        "diagnose-macos-vulkan-wine:",
        "diagnose-linux-vulkan-wine:",
    ]:
        require_contains("justfile", expected)

    require_not_contains(
        "packages/konyak_cli/lib/src/domain/bottle/bottle_runtime_settings_models.dart",
        ".macosEnvironment()",
    )
    require_contains(
        "packages/konyak_cli/lib/src/domain/bottle/bottle_runtime_settings_models.dart",
        "linuxEnvironment()",
    )
    require_contains(
        "runtime/konyak-macos-runtime/.github/workflows/build-runtime.yml",
        "./scripts/check-wine-addon-versions.zsh",
    )
    for relative_path in [
        "runtime/konyak-macos-runtime/.github/workflows/build-runtime.yml",
        "runtime/konyak-macos-runtime/.github/workflows/promote-runtime-candidate.yml",
        "runtime/konyak-macos-runtime/.github/workflows/smoke-runtime-artifacts.yml",
    ]:
        require_contains(relative_path, "./scripts/check-winetricks-component.zsh")
    require_contains(
        "scripts/run_macos_runtime_cli_smoke.zsh",
        "list-winetricks-verbs",
    )
    require_contains(
        "packages/konyak_cli/lib/src/domain/runtime/runtime_platform_support.dart",
        "<String>['verbs.txt']",
    )


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
    require_refactoring_file_growth_limits()
    require_flutter_view_model_extraction_boundaries()
    require_refactoring_documentation_cleanup()
    require_semantic_constructor_value_object_fronts()
    require_cli_parser_option_boundaries()
    require_cli_command_dispatch_boundaries()
    require_flutter_dialog_decision_boundaries()
    require_flutter_update_optional_field_boundaries()
    require_refactoring_governance_allowance_cleanup()
    require_typed_domain_string_maps()
    require_runtime_ssot_rules()
    require_no_cli_state_errors()
    require_program_run_request_builders_split()
    require_typed_program_run_request_boundary()
    require_runner_kind_catalog_boundary()
    require_runtime_platform_definition_type_fronts()
    require_runtime_model_type_fronts()
    require_typed_program_run_planner_boundary()
    require_typed_bottle_command_planner_boundary()
    require_typed_winetricks_verb_planner_boundary()
    require_typed_wine_process_planner_boundary()
    require_typed_detached_process_starter_boundary()
    require_typed_path_opener_boundary()
    require_typed_runtime_executable_probe_boundary()
    require_typed_winetricks_verb_lister_boundary()
    require_typed_runtime_id_service_boundaries()
    require_typed_bottle_repository_id_boundary()
    require_typed_runtime_settings_setter_boundary()
    require_typed_mutation_model_boundaries()
    require_typed_registry_planner_boundary()
    require_typed_bottle_location_boundary()
    require_wine_process_termination_cli_json_projection()
    require_program_catalog_cli_json_projection()
    require_graphics_backend_hints_cli_json_projection()
    require_program_settings_cli_json_projection()
    require_app_settings_serialization_boundary()
    require_update_record_cli_json_projection()
    require_runtime_validation_cli_json_projection()
    require_runtime_install_progress_io_json_projection()
    require_runtime_record_cli_json_projection()
    require_bottle_metadata_io_json_projection()
    require_bottle_archive_cli_json_projection()
    require_pinned_launcher_manifest_io_json_projection()

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
        "macos-debug-app",
        "fetch-windows-fixture-putty",
        "smoke-macos-finder",
        "smoke-macos-app-cli-bridge",
        "smoke-macos-app-update-handoff",
        "smoke-macos-finder-putty",
        "smoke-macos-runtime-install",
        "smoke-linux-appimage-update-handoff",
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
    require_contains("scripts/build_macos_release.zsh", "finalize_macos_app.zsh")
    require_contains("scripts/finalize_macos_app.zsh", "Konyak-MIT.txt")
    require_contains("scripts/finalize_macos_app.zsh", "THIRD_PARTY_NOTICES.md")
    require_contains("scripts/fetch_windows_fixture_putty.zsh", "putty_version=0.84")
    require_contains(
        "scripts/fetch_windows_fixture_putty.zsh",
        "https://the.earth.li/~sgtatham/putty/0.84/w64/putty.exe",
    )
    require_contains(
        "scripts/fetch_windows_fixture_putty.zsh",
        "7056ca2f6a9f3c525845b116c7bf564ced3284a4083ea80d7e9ef51a16f612c4",
    )
    require_contains(".github/workflows/publish.yml", "fetch_windows_fixture_putty")
    require_contains(".github/workflows/publish.yml", "smoke_macos_finder_integration")
    require_contains(".github/workflows/publish.yml", "smoke_macos_packaged_app_cli_bridge")
    require_contains(
        "scripts/smoke_macos_packaged_app_cli_bridge.zsh",
        "KONYAK_SMOKE_OPEN_EXECUTABLE_AUTO_RUN_BOTTLE_ID",
    )
    require_contains(
        "scripts/smoke_macos_packaged_app_cli_bridge.zsh",
        "KONYAK_ENABLE_SMOKE_HOOKS=1",
    )
    require_contains(
        "scripts/smoke_macos_packaged_app_cli_bridge.zsh",
        "KONYAK_BUNDLE_RESOURCES",
    )
    require_contains("scripts/smoke_macos_packaged_app_cli_bridge.zsh", "run-program")
    require_contains("scripts/build_linux_release.zsh", "Konyak-MIT.txt")
    require_contains("scripts/build_linux_release.zsh", "THIRD_PARTY_NOTICES.md")
    require_not_contains("scripts/finalize_macos_app.zsh", "SOURCE-OFFER.txt")
    require_not_contains("scripts/build_macos_release.zsh", "SOURCE-OFFER.txt")
    require_not_contains("scripts/build_linux_release.zsh", "SOURCE-OFFER.txt")
    require_not_contains("scripts/finalize_macos_app.zsh", "Konyak-GPL-3.0.txt")
    require_not_contains("scripts/build_macos_release.zsh", "Konyak-GPL-3.0.txt")
    require_not_contains("scripts/build_linux_release.zsh", "Konyak-GPL-3.0.txt")
    require_not_contains(
        "scripts/finalize_macos_app.zsh", "Konyak is distributed under GPL-3.0"
    )
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
        "actions/checkout",
        "docs/releases/${tag}.md",
        "source_notes",
    ]:
        require_contains(".github/workflows/publish.yml", expected)
    for expected in [
        "Prepare Konyak Release",
        "scripts/prepare_release.py",
        "dispatch_publish",
        "GH_TOKEN",
        "release_notes",
        "RELEASE_NOTES",
        "--release-notes",
        "contents: write",
        "actions: write",
    ]:
        require_contains(".github/workflows/prepare-release.yml", expected)
    for expected in [
        "prepare-release *ARGS:",
        "draft-release-notes VERSION:",
        "release-candidate-gates:",
        "scripts/prepare_release.py",
        "scripts/draft_release_notes.zsh",
        "scripts/run_release_candidate_gates.zsh",
    ]:
        require_contains("justfile", expected)
    for expected in [
        "gh",
        "workflow",
        "run",
        "publish.yml",
        "--ref",
        "--release-notes",
        "docs/releases",
    ]:
        require_contains("scripts/prepare_release.py", expected)
    for expected in [
        "just verify",
        "just macos-release",
        "smoke-macos-dmg-layout",
        "smoke_macos_app_update_handoff",
        "just linux-release-check",
    ]:
        require_contains("scripts/run_release_candidate_gates.zsh", expected)
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
    require_contains("docs/todo.md", "wineloader start /unix")
    require_contains("docs/todo.md", "serika12345/konyak-macos-runtime")
    require_contains("runtime/macos-wine-release.json", "defaultReleaseTag")
    for expected in [
        "defaultReleaseTag",
        "sourceManifestFileName",
        "sourceManifestSignatureFileName",
        "publicKeyFileName",
    ]:
        require_contains("runtime/linux-wine-release.json", expected)
    require_contains(".gitmodules", "runtime/konyak-linux-runtime")
    require_contains(".gitmodules", "serika12345/konyak-linux-runtime")
    require_contains("docs/todo.md", "Runtimes/macos-wine/bin/wineloader")
    require_contains("docs/todo.md", "Drop live external plist metadata")
    for expected in [
        "Execution Path SSOT",
        "Do not manually invoke packaged Wine executables",
        "Do not create ad hoc `WINEPREFIX` values",
        "Do not suppress Wine Mono/MSHTML addon probing",
        "must match the versions and filenames compiled into",
        "run-winetricks <bottle-id> --verb <verb> --json",
        "macosWinetricks",
        "scripts/run_macos_runtime_cli_smoke.zsh",
        "scripts/run_linux_runtime_cli_smoke.zsh",
    ]:
        require_contains("AGENTS.md", expected)
    require_contains(
        "docs/runtime-integrity-debt-inventory.md",
        "Prefix initialization suppresses Wine addon probing",
    )
    require_contains(
        "docs/runtime-integrity-debt-inventory.md",
        "Runtime install success does not require stack completeness",
    )
    require_contains(
        "docs/todo.md",
        "Remove runtime verification masking and prove prefix/addon integrity",
    )
    for expected in [
        "wine-mono-10.4.1-x86.msi",
        "wine-gecko-2.47.4-x86.msi",
        "wine-gecko-2.47.4-x86_64.msi",
    ]:
        require_contains(
            "runtime/konyak-macos-runtime/scripts/package-binary-components.zsh",
            expected,
        )
    require_contains(
        "runtime/konyak-macos-runtime/scripts/check-wine-addons-component.zsh",
        "wine-gecko-2.47.4-x86_64.msi",
    )
    require_contains("scripts/run_macos_runtime_cli_smoke.zsh", "wine-gecko")
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
    require_contains("docs/release.md", "Prepare Konyak Release")
    require_contains("docs/release.md", "just prepare-release")
    require_contains("docs/release.md", "just release-candidate-gates")
    require_contains("docs/release.md", "docs/releases/v<version>.md")
    require_contains("docs/release.md", "restore the pubspec, remove copied release notes")
    require_contains("docs/vscode-macos.md", "Konyak Flutter (macOS)")
    require_contains("docs/vscode-macos.md", "Hot Reload")
    require_contains("docs/vscode-macos.md", "Agent Edit Watch")
    require_contains("docs/vscode-macos.md", "Konyak: Flutter Run macOS (Agent Watch)")
    require_contains("docs/vscode-macos.md", ".dart_tool/konyak/flutter-sdk")
    require_contains("docs/vscode-macos.md", "prepare_macos_dev_runtime_stack.zsh")
    require_contains("docs/vscode-macos.md", "KONYAK_DEV_MACOS_WINE_STACK_MANIFEST")
    require_contains("docs/vscode-macos.md", "prepare_linux_dev_runtime_source.zsh")
    require_contains("docs/vscode-macos.md", "KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST")
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
        "--dart-define=KONYAK_RUNTIME_PROFILE",
        "--dart-define=KONYAK_MACOS_WINE_HOME",
        "--dart-define=KONYAK_DEV_MACOS_WINE_STACK_MANIFEST",
    ]:
        require_contains(".vscode/launch.json", expected)
        require_contains(".vscode/tasks.json", expected)
    require_contains(".vscode/tasks.json", "scripts/prepare_linux_dev_runtime_source.zsh")
    require_contains(".vscode/launch.json", "Konyak: Prepare Linux Runtime Source")
    require_contains(
        ".vscode/launch.json",
        "--dart-define=KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST",
    )
    require_contains(
        ".vscode/launch.json",
        "KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST",
    )
    require_contains(
        ".vscode/tasks.json", "KONYAK_DEV_LINUX_WINE_STACK_MANIFEST_CACHE"
    )

    for expected in [
        "--dart-define=KONYAK_RUNTIME_PROFILE",
        "--dart-define=KONYAK_MACOS_WINE_HOME",
        "--dart-define=KONYAK_DEV_MACOS_WINE_STACK_MANIFEST",
    ]:
        require_contains("scripts/flutter_macos_agent_watch.py", expected)

    for expected in [
        "prepare_macos_dev_runtime_stack.zsh",
        "KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST",
        "KONYAK_LINUX_WINE_LIBRARY_PATH",
    ]:
        require_contains("flake.nix", expected)
    for expected in [
        "KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST",
        "KONYAK_DEV_LINUX_WINE_STACK_MANIFEST_CACHE",
        "Linux development runtime components are not generated in the parent repository.",
        "wine-mono",
        "vkd3d-proton",
    ]:
        require_contains("scripts/prepare_linux_dev_runtime_source.zsh", expected)
    for expected in [
        "runtime/linux-wine-release.json",
        "KONYAK_RUNTIME_STACK_SOURCE_MANIFEST",
        "KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST",
        "wine-mono",
        "vkd3d-proton",
    ]:
        require_contains("scripts/resolve_linux_runtime_source_manifest.zsh", expected)
    for expected in [
        "KONYAK_LINUX_WINE_STACK_MANIFEST",
        "KONYAK_LINUX_WINE_STACK_SIGNATURE_URL",
        "KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH",
        "KONYAK_LINUX_WINE_STACK_PUBLIC_KEY_PATH",
    ]:
        require_contains("scripts/build_linux_release.zsh", expected)
    require_contains(
        ".github/workflows/publish.yml",
        "konyak-linux-wine-runtime-stack-source.json.sig",
    )
    require_contains(
        ".github/workflows/publish.yml",
        "smoke_linux_appimage_apprun_env.zsh",
    )
    require_contains(
        ".github/workflows/publish.yml",
        "smoke_linux_appimage_update_handoff.zsh",
    )
    require_contains(
        ".github/workflows/publish.yml",
        "smoke_linux_desktop_integration.zsh",
    )
    require_contains(
        ".github/workflows/publish.yml",
        "smoke_linux_pinned_launcher_integration.zsh",
    )
    for expected in [
        "Verify release candidate",
        "nix develop -c zsh -lc 'just verify'",
        "- verify",
    ]:
        require_contains(".github/workflows/publish.yml", expected)
    for expected in [
        "Linux Runtime CLI Smoke",
        "scripts/run_linux_runtime_cli_smoke.zsh",
        "scripts/run_linux_release_check.zsh",
        "KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST",
    ]:
        require_contains(".github/workflows/linux-runtime-cli-smoke.yml", expected)
    require_contains(
        "scripts/run_linux_runtime_cli_smoke.zsh",
        "env -u KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST",
    )
    require_not_contains(
        ".github/workflows/linux-runtime-cli-smoke.yml",
        "vars.KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST != ''",
    )
    require_contains("justfile", "linux-runtime-cli-smoke:")
    require_contains("justfile", "linux-desktop-integration-smoke:")
    require_contains("justfile", "linux-pinned-launcher-smoke:")
    require_contains("justfile", "smoke-linux-appimage-update-handoff:")
    require_contains("justfile", "linux-release-check:")
    for expected in [
        "Konyak: Build Linux AppImage",
        "Konyak: Smoke Linux Runtime Install",
        "Konyak: Build Linux AppImage + Runtime Install Smoke",
        "Konyak: Draft Release Notes",
        "Konyak: Release From Draft Notes",
        "just linux-release-check",
    ]:
        require_contains(".vscode/tasks.json", expected)
    for expected in [
        "Konyak: Draft Release Notes",
        "Konyak: Release From Draft Notes",
        "--gate \\\"just release-candidate-gates\\\"",
        "--dispatch-publish",
    ]:
        require_contains(".vscode/tasks.json", expected)
    for expected in [
        "KONYAK_LINUX_RELEASE_CHECK_SKIP_RUNTIME_INSTALL",
        "smoke_linux_release_metadata.zsh",
        "smoke_linux_appimage_update_handoff.zsh",
        "smoke_linux_desktop_integration.zsh",
        "smoke_linux_pinned_launcher_integration.zsh",
        "run_linux_runtime_cli_smoke.zsh",
    ]:
        require_contains("scripts/run_linux_release_check.zsh", expected)
    require_contains("docs/vscode-macos.md", "Konyak: Build Linux AppImage + Runtime Install Smoke")
    require_contains("docs/vscode-macos.md", "Konyak: Draft Release Notes")
    require_contains("docs/vscode-macos.md", "Konyak: Release From Draft Notes")
    require_contains("docs/release.md", "just linux-release-check")
    require_not_contains("scripts/prepare_linux_dev_runtime_source.zsh", "winetricks list-all")
    require_not_contains("scripts/prepare_linux_dev_runtime_source.zsh", "/nix/store")
    require_contains(
        "scripts/prepare_macos_dev_runtime_stack.zsh",
        "macOS runtime inputs must be complete source manifests",
    )
    require_not_contains("scripts/prepare_macos_dev_runtime_stack.zsh", "WINETRICKS_SCRIPT_SHA256")
    require_not_contains("scripts/prepare_macos_dev_runtime_stack.zsh", "winetricks list-all")
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
        require_konyak_cli_public_exports()
        require_konyak_cli_public_facade_signature()
        require_not_contains(
            "packages/konyak_cli/lib/src/cli/cli_commands.dart",
            "DartIo",
        )
        require_cli_injected_runner_has_no_dartio_defaults()
        require_not_contains(
            "packages/konyak_cli/lib/src/cli/cli_program_run_handlers.dart",
            "DartIoProgramGraphicsBackendHintsInspector()",
        )

        if (ROOT / "apps/konyak").exists():
            require_app_version_sources_match()

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
