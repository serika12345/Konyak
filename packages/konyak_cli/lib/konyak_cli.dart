import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';

part 'src/cli_commands.dart';
part 'src/cli_app_runtime_handlers.dart';
part 'src/cli_wine_process_handlers.dart';
part 'src/cli_bottle_read_handlers.dart';
part 'src/cli_bottle_mutation_handlers.dart';
part 'src/cli_pinned_program_handlers.dart';
part 'src/cli_program_run_handlers.dart';
part 'src/cli_location_winetricks_handlers.dart';
part 'src/cli_parsers.dart';
part 'src/cli_app_process_parsers.dart';
part 'src/cli_bottle_parsers.dart';
part 'src/cli_program_parsers.dart';
part 'src/cli_runtime_parsers.dart';
part 'src/cli_results.dart';
part 'src/cli_program_results.dart';
part 'src/cli_bottle_results.dart';
part 'src/cli_app_process_results.dart';
part 'src/cli_update_runtime_results.dart';
part 'src/common_helpers.dart';
part 'src/storage_paths.dart';
part 'src/macos_pinned_launchers.dart';
part 'src/macos_pinned_launcher_cleanup.dart';
part 'src/macos_pinned_launcher_icons.dart';
part 'src/macos_pinned_launcher_manifests.dart';
part 'src/macos_pinned_launcher_templates.dart';
part 'src/linux_integration.dart';
part 'src/linux_external_program_launchers.dart';
part 'src/linux_file_associations.dart';
part 'src/bottle_archives.dart';
part 'src/model_constants.dart';
part 'src/app_settings_models.dart';
part 'src/bottle_runtime_settings_models.dart';
part 'src/cli_result_model.dart';
part 'src/bottle_models.dart';
part 'src/program_settings_models.dart';
part 'src/repository_interfaces.dart';
part 'src/program_catalog_models.dart';
part 'src/bottle_mutation_models.dart';
part 'src/program_mutation_models.dart';
part 'src/program_run_models.dart';
part 'src/repository_exceptions.dart';
part 'src/program_discovery.dart';
part 'src/platform_io.dart';
part 'src/platform_paths.dart';
part 'src/platform_runtime_sources.dart';
part 'src/platform_update_handoff.dart';
part 'src/platform_terminal_commands.dart';
part 'src/program_shortcut_metadata.dart';
part 'src/wine_process_metadata.dart';
part 'src/pe_program_metadata.dart';
part 'src/pe_program_icons.dart';
part 'src/pe_program_image.dart';
part 'src/pe_program_resources.dart';
part 'src/pe_program_versions.dart';
part 'src/program_argument_support.dart';
part 'src/program_registry_settings.dart';
part 'src/program_winetricks_support.dart';
part 'src/pinned_programs.dart';
part 'src/program_runner.dart';
part 'src/program_io_services.dart';
part 'src/app_settings_repositories.dart';
part 'src/memory_bottle_repository.dart';
part 'src/composite_bottle_repository.dart';
part 'src/file_bottle_repository.dart';
part 'src/runtime_install_operations.dart';
part 'src/runtime_package_installation.dart';
part 'src/gptk_wine_installation.dart';
part 'src/macos_wine_installation.dart';
part 'src/macos_wine_archive_installation.dart';
part 'src/macos_wine_layout_normalization.dart';
part 'src/linux_wine_installation.dart';
part 'src/linux_wine_install_operations.dart';
part 'src/runtime_platform_support.dart';
part 'src/runtime_platform_records.dart';
part 'src/runtime_source_manifest_support.dart';
part 'src/runtime_source_archive_support.dart';
part 'src/runtime_archive_install_support.dart';
part 'src/runtime_gptk_support.dart';
part 'src/runtime_update_support.dart';
part 'src/runtime_validation_support.dart';
part 'src/wine_run_requests.dart';
part 'src/runtime_validation.dart';
part 'src/runtime_validation_models.dart';
part 'src/runtime_executable_probe.dart';
part 'src/macos_runtime_validator.dart';
part 'src/macos_setup_checker.dart';
part 'src/linux_program_run_requests.dart';
part 'src/macos_program_run_requests.dart';
part 'src/updates.dart';
part 'src/update_records.dart';
part 'src/release_metadata_fetcher.dart';
part 'src/runtime_update_checker.dart';
part 'src/app_update_checker.dart';
part 'src/app_update_installer.dart';
part 'src/app_update_handoff_installers.dart';
part 'src/runtime_models.dart';
part 'src/runtime_source_bundle_models.dart';
part 'src/runtime_probes.dart';
part 'src/runtime_catalogs.dart';

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
            'bottleId': bottle.id,
            'bottlePath': bottle.path,
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
      'bottleId': request.bottleId,
      'programPath': request.programPath,
      'runnerKind': request.runnerKind,
      'executable': request.executable,
      'workingDirectory': request.workingDirectory,
      'argv': request.argv,
      'logPath': request.logPath,
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
      'bottleId': request.bottleId,
      'programPath': request.programPath,
      'runnerKind': request.runnerKind,
      'executable': request.executable,
      'workingDirectory': request.workingDirectory,
      'argv': request.argv,
      'logPath': request.logPath,
    },
  );
}

CliResult? _ensureWinetricksScriptForRun({
  required ProgramRunRequest request,
  required WinetricksScriptInstaller scriptInstaller,
}) {
  if (request.runnerKind != 'macosWinetricks') {
    return null;
  }

  final installResult = scriptInstaller.installIfMissing(
    executable: request.executable,
  );
  return switch (installResult) {
    WinetricksScriptInstallCompleted() => null,
    WinetricksScriptInstallFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'winetricksUnavailable',
      message: message,
    ),
  };
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
      request.environment.entries
          .map((entry) => MapEntry(entry.key, '${entry.key}=${entry.value}'))
          .toList(growable: false)
        ..sort((left, right) => left.key.compareTo(right.key));

  return <String>[
    'Konyak Wine Run Log',
    '',
    '[Process]',
    'Runner Kind: ${request.runnerKind}',
    'Executable: ${request.executable}',
    'Working Directory: ${request.workingDirectory ?? ''}',
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
