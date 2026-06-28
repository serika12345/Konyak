import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:args/args.dart' hide Option;
import 'package:crypto/crypto.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';

import 'src/domain/shared/domain_value_objects.dart';

export 'src/domain/shared/domain_value_objects.dart';

part 'src/cli/cli_commands.dart';
part 'src/cli/cli_app_handlers.dart';
part 'src/cli/cli_host_integration_handlers.dart';
part 'src/cli/cli_app_runtime_handlers.dart';
part 'src/cli/cli_wine_process_handlers.dart';
part 'src/cli/cli_bottle_read_handlers.dart';
part 'src/cli/cli_bottle_mutation_handlers.dart';
part 'src/cli/cli_pinned_program_handlers.dart';
part 'src/cli/cli_program_run_handlers.dart';
part 'src/cli/cli_location_winetricks_handlers.dart';
part 'src/cli/cli_parsers.dart';
part 'src/cli/cli_app_process_parsers.dart';
part 'src/cli/cli_bottle_parsers.dart';
part 'src/cli/cli_program_mutation_parsers.dart';
part 'src/cli/cli_program_run_parsers.dart';
part 'src/cli/cli_location_parsers.dart';
part 'src/cli/cli_runtime_parsers.dart';
part 'src/cli/cli_results.dart';
part 'src/cli/cli_program_results.dart';
part 'src/cli/cli_bottle_results.dart';
part 'src/cli/cli_app_process_results.dart';
part 'src/cli/cli_update_runtime_results.dart';
part 'src/shared/common_helpers.dart';
part 'src/io/external_payload_helpers.dart';
part 'src/storage/storage_paths.dart';
part 'src/io/repository_storage_io.dart';
part 'src/io/macos_pinned_launchers.dart';
part 'src/io/macos_pinned_launcher_cleanup.dart';
part 'src/io/macos_pinned_launcher_bundle_io.dart';
part 'src/io/macos_pinned_launcher_icons.dart';
part 'src/io/macos_pinned_launcher_manifest_io.dart';
part 'src/io/macos_pinned_launcher_manifests.dart';
part 'src/io/linux_pinned_launchers.dart';
part 'src/platform/macos/macos_pinned_launcher_templates.dart';
part 'src/platform/linux/linux_integration.dart';
part 'src/io/external_program_launch_records.dart';
part 'src/io/linux_external_program_launcher_io.dart';
part 'src/io/linux_external_program_launchers.dart';
part 'src/io/linux_file_association_io.dart';
part 'src/io/linux_file_associations.dart';
part 'src/io/bottle_archives.dart';
part 'src/io/directory_copy_support.dart';
part 'src/shared/model_constants.dart';
part 'src/domain/app/app_settings_models.dart';
part 'src/domain/bottle/bottle_runtime_settings_models.dart';
part 'src/cli/cli_result_model.dart';
part 'src/domain/bottle/bottle_models.dart';
part 'src/domain/program/program_settings_models.dart';
part 'src/repository/repository_interfaces.dart';
part 'src/domain/program/program_catalog_models.dart';
part 'src/domain/bottle/bottle_mutation_models.dart';
part 'src/domain/program/program_mutation_models.dart';
part 'src/domain/program/program_run_environment.dart';
part 'src/domain/runtime/host_environment.dart';
part 'src/domain/program/program_run_models.dart';
part 'src/repository/repository_exceptions.dart';
part 'src/io/io_result.dart';
part 'src/io/program_discovery.dart';
part 'src/io/program_metadata_io.dart';
part 'src/io/platform_io.dart';
part 'src/io/platform_host_paths.dart';
part 'src/platform/platform_location_paths.dart';
part 'src/domain/runtime/wine_runtime_paths.dart';
part 'src/io/app_update_paths.dart';
part 'src/domain/runtime/runtime_profile_environment.dart';
part 'src/io/platform_runtime_sources.dart';
part 'src/platform/platform_update_handoff.dart';
part 'src/platform/platform_terminal_commands.dart';
part 'src/io/program_shortcut_metadata.dart';
part 'src/io/program_shortcut_metadata_io.dart';
part 'src/io/pinned_program_availability_io.dart';
part 'src/io/wine_process_metadata.dart';
part 'src/io/wine_process_metadata_io.dart';
part 'src/io/pe_program_metadata.dart';
part 'src/io/pe_program_icons.dart';
part 'src/domain/program/program_graphics_backend_hints.dart';
part 'src/io/pe_program_icon_io.dart';
part 'src/io/program_graphics_backend_hints_io.dart';
part 'src/io/pe_program_image.dart';
part 'src/io/pe_program_resources.dart';
part 'src/io/pe_program_versions.dart';
part 'src/domain/program/program_argument_support.dart';
part 'src/domain/program/program_registry_models.dart';
part 'src/domain/program/program_registry_plans.dart';
part 'src/io/program_registry_parsers.dart';
part 'src/io/program_winetricks_support.dart';
part 'src/io/winetricks_io.dart';
part 'src/domain/program/pinned_programs.dart';
part 'src/domain/program/program_runner.dart';
part 'src/io/program_io_services.dart';
part 'src/io/app_settings_repositories.dart';
part 'src/repository/memory_bottle_repository.dart';
part 'src/repository/composite_bottle_repository.dart';
part 'src/io/file_bottle_repository_io.dart';
part 'src/repository/file_bottle_repository_archive_operations.dart';
part 'src/repository/file_bottle_repository_mutation_operations.dart';
part 'src/repository/file_bottle_repository_program_operations.dart';
part 'src/repository/file_bottle_repository_read_operations.dart';
part 'src/repository/file_bottle_repository.dart';
part 'src/domain/runtime/runtime_install_operation_models.dart';
part 'src/domain/runtime/runtime_component_versions.dart';
part 'src/platform/macos/macos_wine_install_requests.dart';
part 'src/platform/linux/linux_wine_install_requests.dart';
part 'src/platform/macos/macos_wine_install_results.dart';
part 'src/platform/linux/linux_wine_install_results.dart';
part 'src/domain/runtime/runtime_install_plans.dart';
part 'src/domain/runtime/runtime_package_installation.dart';
part 'src/io/gptk_wine_installation.dart';
part 'src/io/macos_wine_installation.dart';
part 'src/io/macos_wine_archive_installation.dart';
part 'src/io/macos_wine_layout_normalization.dart';
part 'src/io/linux_wine_installation.dart';
part 'src/io/linux_wine_install_operations.dart';
part 'src/domain/runtime/runtime_platform_support.dart';
part 'src/io/runtime_platform_records.dart';
part 'src/io/runtime_stack_manifest_io.dart';
part 'src/io/runtime_source_manifest_support.dart';
part 'src/domain/runtime/runtime_source_archive_planning.dart';
part 'src/io/runtime_source_archive_downloads.dart';
part 'src/io/runtime_source_archive_support.dart';
part 'src/io/runtime_archive_install_support.dart';
part 'src/io/runtime_gptk_support.dart';
part 'src/domain/runtime/runtime_update_support.dart';
part 'src/domain/runtime/runtime_validation_support.dart';
part 'src/io/wine_run_requests.dart';
part 'src/domain/runtime/runtime_validation.dart';
part 'src/domain/runtime/runtime_validation_models.dart';
part 'src/io/runtime_executable_probe.dart';
part 'src/platform/macos/macos_runtime_validator.dart';
part 'src/platform/macos/macos_setup_checker.dart';
part 'src/platform/linux/linux_program_run_requests.dart';
part 'src/platform/macos/macos_program_run_requests.dart';
part 'src/domain/update/updates.dart';
part 'src/domain/update/update_records.dart';
part 'src/io/release_metadata_fetcher.dart';
part 'src/domain/runtime/runtime_update_checker.dart';
part 'src/io/runtime_release_metadata.dart';
part 'src/io/runtime_release_metadata_assets.dart';
part 'src/io/runtime_release_metadata_source_manifests.dart';
part 'src/domain/update/app_update_checker.dart';
part 'src/io/app_update_installer.dart';
part 'src/io/app_update_handoff_installers.dart';
part 'src/domain/runtime/runtime_models.dart';
part 'src/domain/runtime/runtime_source_bundle_models.dart';
part 'src/io/runtime_probes.dart';
part 'src/domain/runtime/runtime_catalogs.dart';

CliResult _jsonSuccess(Map<String, Object?> payload, {int exitCode = 0}) {
  return CliResult(
    exitCode: exitCode,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      ...payload,
    }),
    stderr: '',
  );
}

CliResult _unavailableJsonError({
  required String code,
  required String subject,
}) {
  return _jsonError(
    exitCode: 74,
    code: code,
    message: '$subject is not configured.',
  );
}

CliResult _jsonError({
  required int exitCode,
  required String code,
  required String message,
  Map<String, Object?> extra = const <String, Object?>{},
}) {
  return CliResult(
    exitCode: exitCode,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'error': <String, Object?>{'code': code, 'message': message, ...extra},
    }),
    stderr: '',
  );
}

CliResult _bottleNotFoundError(String bottleId) {
  return _jsonError(
    exitCode: 66,
    code: 'bottleNotFound',
    message: 'Bottle not found.',
    extra: <String, Object?>{'bottleId': bottleId},
  );
}

CliResult _createdBottleJsonResult({
  required BottleRecord bottle,
  required BottlePrefixInitializer? bottlePrefixInitializer,
}) {
  final initializer = bottlePrefixInitializer;
  if (initializer != null) {
    final initializationResult = initializer.initialize(bottle);
    switch (initializationResult) {
      case BottlePrefixInitialized():
        break;
      case BottlePrefixInitializationFailed(:final message):
        return _jsonError(
          exitCode: 75,
          code: 'bottlePrefixInitializationFailed',
          message: message,
          extra: <String, Object?>{
            'bottleId': bottle.id.value,
            'bottlePath': bottle.path.value,
          },
        );
    }
  }

  return _bottleJsonResult(bottle);
}

CliResult _programRunJsonResult({
  required ProgramRunRequest request,
  required int processExitCode,
}) {
  return _jsonSuccess(<String, Object?>{
    'run': <String, Object?>{
      'bottleId': request.bottleId.value,
      'programPath': request.programPath.value,
      'runnerKind': request.runnerKind.value,
      'executable': request.executable.value,
      'workingDirectory': request.workingDirectory.toNullable()?.value,
      'argv': request.argv,
      'logPath': request.logPath.value,
      'logFileCreated': request.createLogFile,
      'processExitCode': processExitCode,
    },
  });
}

CliResult _programRunFailedJsonResult({
  required ProgramRunRequest request,
  required String message,
}) {
  return _jsonError(
    exitCode: 75,
    code: 'programRunFailed',
    message: message,
    extra: <String, Object?>{
      'bottleId': request.bottleId.value,
      'programPath': request.programPath.value,
      'runnerKind': request.runnerKind.value,
      'executable': request.executable.value,
      'workingDirectory': request.workingDirectory.toNullable()?.value,
      'argv': request.argv,
      'logPath': request.logPath.value,
      'logFileCreated': request.createLogFile,
    },
  );
}

String _programRunLog(ProgramRunRequest request, ProcessResult result) {
  final stdout = _processOutputToString(result.stdout);
  final stderr = _processOutputToString(result.stderr);

  return _programRunLogContent(
    request: request,
    processExitCode: result.exitCode,
    stdout: stdout,
    stderr: stderr,
  );
}

String _programRunStartupFailureLog(
  ProgramRunRequest request,
  String startupError,
) {
  return _programRunLogContent(
    request: request,
    startupError: startupError,
    stdout: '',
    stderr: '',
  );
}

String _programRunLogContent({
  required ProgramRunRequest request,
  required String stdout,
  required String stderr,
  int? processExitCode,
  String? startupError,
}) {
  final environmentLines =
      request.environment
          .toMap()
          .entries
          .map((entry) => MapEntry(entry.key, '${entry.key}=${entry.value}'))
          .toList(growable: false)
        ..sort((left, right) => left.key.compareTo(right.key));

  return <String>[
    'Konyak Wine Run Log',
    '',
    '[Process]',
    'Runner Kind: ${request.runnerKind.value}',
    'Executable: ${request.executable.value}',
    'Working Directory: ${request.workingDirectory.map((value) => value.value).getOrElse(() => '')}',
    'Arguments: ${jsonEncode(request.arguments)}',
    'argv: ${jsonEncode(request.argv)}',
    if (processExitCode != null) 'Process Exit Code: $processExitCode',
    if (processExitCode != null) 'exitCode: $processExitCode',
    if (startupError != null) 'Startup Error: $startupError',
    '',
    '[Environment]',
    ...environmentLines.map((entry) => entry.value),
    '',
    '[stdout]',
    stdout,
    '',
    '[stderr]',
    stderr,
    '',
  ].join('\n');
}

String _programRunnerFailureMessage({
  required String executable,
  required String message,
}) {
  if (message == 'No such file or directory') {
    return 'Runner executable `$executable` was not found.';
  }

  return message;
}
