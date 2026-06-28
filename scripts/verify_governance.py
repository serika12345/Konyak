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
    expected_constructor_terms = [
        "required this.bottleId",
        "required this.programPath",
        "required this.runnerKind",
        "required this.executable",
        "required this.arguments",
        "required this.logPath",
        "this.workingDirectory = const Option.none()",
        "final BottleId bottleId",
        "final ProgramPath programPath",
        "final RunnerKind runnerKind",
        "final ProgramExecutable executable",
        "final ProgramRunArguments arguments",
        "final ProgramLogPath logPath",
        "final Option<ProgramWorkingDirectoryPath> workingDirectory",
    ]
    for expected in expected_constructor_terms:
        if expected not in request_models:
            raise AssertionError(
                "ProgramRunRequest must expose a typed domain constructor term: "
                f"{expected}"
            )

    start = request_models.find("class ProgramRunRequest {")
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
        "required BottleCommand supportedCommand",
        "supportedBottleCommand(command)",
        "supportedCommand.value == 'terminal'",
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
        "Option.of(supportedCommand)",
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
        "List<String> wineArgumentsForBottleCommand(BottleCommand command)",
        "Option<BottleCommand> supportedBottleCommand(BottleCommand command)",
        "final normalized = command.value.trim().toLowerCase();",
        "Option.of(BottleCommand(normalized))",
    ]
    for expected in expected_support_terms:
        if expected not in argument_support:
            raise AssertionError(
                "program argument support must expose typed bottle command "
                f"helpers: {expected}"
            )

    forbidden_support_terms = [
        "List<String> wineArgumentsForBottleCommand(String command)",
        "Option<String> supportedBottleCommand(String command)",
    ]
    for forbidden in forbidden_support_terms:
        if forbidden in argument_support:
            raise AssertionError(
                "program argument support must not expose primitive bottle "
                f"command helpers: {forbidden}"
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
        "winedbgAttachProcessId(processId)",
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

    process_results_path = (
        "packages/konyak_cli/lib/src/cli/cli_app_process_results.dart"
    )
    process_results = read_text(process_results_path)
    expected_process_result_terms = [
        "required WineProcessId processId",
        "processId: processId,",
        "processId: Option.of(processId.value)",
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


def require_wine_process_termination_cli_json_projection() -> None:
    domain_path = "packages/konyak_cli/lib/src/domain/program/program_run_models.dart"
    domain = read_text(domain_path)
    record_match = re.search(
        r"class WineProcessTerminationRecord \{(?P<body>.*?)\n\}",
        domain,
        flags=re.DOTALL,
    )
    if record_match is None:
        raise AssertionError("WineProcessTerminationRecord must exist")
    if "toJson(" in record_match.group("body"):
        raise AssertionError(
            "WineProcessTerminationRecord must not own CLI JSON projection"
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
        "ProgramGraphicsBackendHints",
        "ProgramGraphicsBackendSignal",
        "ProgramGraphicsBackendSuggestion",
    ]:
        if "toJson(" in class_section(class_name):
            raise AssertionError(
                f"{class_name} must not own CLI JSON projection"
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

    require_contains(
        "packages/konyak_cli/lib/src/repository/repository_interfaces.dart",
        "IoResult<Option<BottleRecord>> findBottle(String id);",
    )
    require_not_contains(
        "packages/konyak_cli/lib/src/repository/repository_interfaces.dart",
        "IoResult<BottleRecord?> findBottle",
    )
    for expected in [
        "final BottleId id;",
        "final BottleName name;",
        "final BottlePath path;",
        "final WindowsVersion windowsVersion;",
        "final IList<PinnedProgramRecord> pinnedPrograms;",
        "final ProgramName name;",
        "final ProgramPath path;",
        "final Option<ProgramIconPath> iconPath;",
        "Option<String> iconPath = const Option.none()",
        "iconPath.map(",
    ]:
        require_contains("packages/konyak_cli/lib/src/domain/bottle/bottle_models.dart", expected)
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
        "final List<PinnedProgramRecord> pinnedPrograms;",
    )
    require_contains(
        "packages/konyak_cli/lib/src/domain/program/program_settings_models.dart",
        "final ProgramEnvironmentOverrides environment;",
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
        "final Option<ProgramMetadataRecord> metadata;",
        "final Option<ProgramPath> hostPath;",
        "Option<ProgramMetadataRecord> extract({",
        "final Option<ProgramArchitecture> architecture;",
        "final Option<ProgramFileDescription> fileDescription;",
        "final Option<ProgramProductName> productName;",
        "final Option<ProgramCompanyName> companyName;",
        "final Option<ProgramFileVersion> fileVersion;",
        "final Option<ProgramProductVersion> productVersion;",
        "final Option<ProgramIconPath> iconPath;",
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
        "final Option<RuntimeVersion> currentVersion;",
        "final Option<RuntimeVersion> latestVersion;",
        "final Option<RuntimeVersionUrl> versionUrl;",
        "final Option<RuntimeArchiveUrl> archiveUrl;",
        "final Option<RuntimeSourceManifestUrl> sourceManifestUrl;",
        "final Option<RuntimeSourceManifestSignatureUrl> sourceManifestSignatureUrl;",
        "final Option<AppVersion> currentVersion;",
        "final Option<ReleaseVersion> latestVersion;",
        "final Option<AppArchiveUrl> archiveUrl;",
        "final Option<AppArchiveSha256> archiveSha256;",
        "final Option<AppInstallPath> installPath;",
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
        "final Option<RuntimeArchiveChecksumValue> archiveSha256;",
    )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/runtime/runtime_package_installation.dart",
        "final String? archiveSha256;",
    )
    require_contains(
        "packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart",
        "final Option<RuntimeVersion> version;",
    )
    require_not_contains(
        "packages/konyak_cli/lib/src/domain/runtime/runtime_models.dart",
        "final String? version;",
    )
    for expected in [
        "final Option<RuntimeDistributionKind> distributionKind;",
        "final Option<bool> isInstalled;",
        "final Option<RuntimeArchiveUrl> archiveUrl;",
        "final Option<RuntimeVersionUrl> versionUrl;",
        "final Option<RuntimeComponentPath> applicationSupportPath;",
        "final Option<RuntimeComponentPath> libraryPath;",
        "final Option<RuntimeComponentPath> executablePath;",
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

    for expected in [
        "class ProgramPinFailed",
        "class ProgramUpdateFailed",
        "class ProgramSettingsReadFailed",
        "class ProgramSettingsUpdateFailed",
    ]:
        require_contains("packages/konyak_cli/lib/src/domain/program/program_mutation_models.dart", expected)

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
    require_typed_domain_string_maps()
    require_runtime_ssot_rules()
    require_no_cli_state_errors()
    require_program_run_request_builders_split()
    require_typed_program_run_request_boundary()
    require_typed_program_run_planner_boundary()
    require_typed_bottle_command_planner_boundary()
    require_typed_winetricks_verb_planner_boundary()
    require_typed_wine_process_planner_boundary()
    require_wine_process_termination_cli_json_projection()
    require_program_catalog_cli_json_projection()
    require_graphics_backend_hints_cli_json_projection()
    require_program_settings_cli_json_projection()

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
