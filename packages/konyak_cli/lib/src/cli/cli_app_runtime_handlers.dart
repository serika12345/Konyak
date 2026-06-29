import '../domain/program/program_run_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/runtime/runtime_validation_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../domain/update/update_records.dart';
import '../io/gptk_wine_installation.dart';
import '../io/runtime_install_progress_io.dart';
import '../platform/linux/linux_wine_install_requests.dart';
import '../platform/linux/linux_wine_install_results.dart';
import '../platform/macos/macos_setup_checker.dart';
import '../platform/macos/macos_wine_install_requests.dart';
import '../platform/macos/macos_wine_install_results.dart';
import 'cli_commands.dart';
import 'cli_json_helpers.dart';
import 'cli_location_winetricks_handlers.dart';
import 'cli_result_model.dart';
import 'cli_runtime_parsers.dart';
import 'cli_runtime_record_json.dart';
import 'cli_runtime_validation_json.dart';
import 'cli_update_json.dart';
import 'cli_update_runtime_results.dart';

CliResult? handleRuntimeCommand(
  List<String> arguments,
  CliCommandContext context,
) {
  if (isJsonRuntimeListCommand(arguments)) {
    return jsonSuccess(<String, Object?>{
      'runtimes': context.runtimeCatalog
          .listRuntimes()
          .map(runtimeRecordJson)
          .toList(growable: false),
    });
  }

  if (isJsonMacosSetupCheckCommand(arguments)) {
    final checker = context.macosSetupChecker;
    if (checker == null) {
      return unavailableJsonError(
        code: 'macosSetupCheckerUnavailable',
        subject: 'macOS setup checker',
      );
    }

    return switch (checker.check()) {
      MacosSetupCheckCompleted(:final status) => jsonSuccess(<String, Object?>{
        'macosSetup': status.toJson(),
      }),
      MacosSetupCheckFailed(:final message) => jsonError(
        exitCode: 75,
        code: 'macosSetupCheckFailed',
        message: message,
      ),
    };
  }

  final gptkWineInstallRequest = parseJsonGptkWineInstallRequest(arguments);
  if (gptkWineInstallRequest != null) {
    final installer = context.gptkWineInstaller;
    if (installer == null) {
      return unavailableJsonError(
        code: 'gptkWineInstallerUnavailable',
        subject: 'GPTK/D3DMetal importer',
      );
    }

    return switch (installer.install(gptkWineInstallRequest)) {
      GptkWineInstallCompleted(:final record) => jsonSuccess(<String, Object?>{
        'gptkWineInstall': record.toJson(),
      }),
      GptkWineInstallFailed(:final message) => jsonError(
        exitCode: 75,
        code: 'gptkWineInstallFailed',
        message: message,
      ),
    };
  }

  final openUrl = parseJsonOpenUrlCommand(arguments);
  if (openUrl != null) {
    return openUrlJsonResult(openUrl, context.pathOpener);
  }

  final runtimeUpdateId = parseJsonRuntimeIdCommand(
    arguments,
    'check-runtime-update',
  );
  if (runtimeUpdateId != null) {
    return runtimeUpdateCheckJsonResult(
      runtimeId: RuntimeId(runtimeUpdateId),
      runtimeUpdateChecker: context.runtimeUpdateChecker,
    );
  }

  final runtimeUpdateInstallId = parseJsonRuntimeIdCommand(
    arguments,
    'install-runtime-update',
  );
  if (runtimeUpdateInstallId != null) {
    return installRuntimeUpdateJsonResult(
      runtimeId: RuntimeId(runtimeUpdateInstallId),
      runtimeUpdateChecker: context.runtimeUpdateChecker,
      macosWineInstaller: context.macosWineInstaller,
      linuxWineInstaller: context.linuxWineInstaller,
    );
  }

  final runtimeValidationId = parseJsonRuntimeIdCommand(
    arguments,
    'validate-runtime',
  );
  if (runtimeValidationId != null) {
    return runtimeValidationJsonResult(
      runtimeId: RuntimeId(runtimeValidationId),
      runtimeValidator: context.runtimeValidator,
    );
  }

  final macosWineInstallRequest = parseJsonMacosWineInstallRequest(arguments);
  if (macosWineInstallRequest != null) {
    return macosWineInstallJsonResult(
      request: macosWineInstallRequest,
      installer: context.macosWineInstaller,
      progressSink: context.runtimeInstallProgressSink,
    );
  }

  final linuxWineInstallRequest = parseJsonLinuxWineInstallRequest(arguments);
  if (linuxWineInstallRequest != null) {
    return linuxWineInstallJsonResult(
      request: linuxWineInstallRequest,
      installer: context.linuxWineInstaller,
      progressSink: context.runtimeInstallProgressSink,
    );
  }

  return null;
}

CliResult openUrlJsonResult(String openUrl, PathOpener? pathOpener) {
  if (pathOpener == null) {
    return pathOpenerUnavailableError();
  }
  final openResult = pathOpener.openPath(PathOpenTarget(openUrl));
  return switch (openResult) {
    PathOpenCompleted() => jsonSuccess(<String, Object?>{
      'openedUrl': <String, Object?>{'url': openUrl},
    }),
    PathOpenFailed(:final message) => jsonError(
      exitCode: 75,
      code: 'urlOpenFailed',
      message: message,
      extra: <String, Object?>{'url': openUrl},
    ),
  };
}

CliResult runtimeUpdateCheckJsonResult({
  required RuntimeId runtimeId,
  required RuntimeUpdateChecker? runtimeUpdateChecker,
}) {
  if (runtimeUpdateChecker == null) {
    return unavailableJsonError(
      code: 'runtimeUpdateCheckerUnavailable',
      subject: 'Runtime update checker',
    );
  }

  return switch (runtimeUpdateChecker.check(runtimeId)) {
    RuntimeUpdateCheckCompleted(:final update) => jsonSuccess(<String, Object?>{
      'runtimeUpdate': runtimeUpdateRecordJson(update),
    }),
    RuntimeUpdateRuntimeNotFound(:final runtimeId) => jsonError(
      exitCode: 66,
      code: 'runtimeNotFound',
      message: 'Runtime not found.',
      extra: <String, Object?>{'runtimeId': runtimeId.value},
    ),
    RuntimeUpdateCheckFailed(:final message) => jsonError(
      exitCode: 75,
      code: 'runtimeUpdateCheckFailed',
      message: message,
    ),
  };
}

CliResult runtimeValidationJsonResult({
  required RuntimeId runtimeId,
  required RuntimeValidator? runtimeValidator,
}) {
  if (runtimeValidator == null) {
    return unavailableJsonError(
      code: 'runtimeValidatorUnavailable',
      subject: 'Runtime validator',
    );
  }

  return switch (runtimeValidator.validate(runtimeId)) {
    RuntimeValidationCompleted(:final validation) => jsonSuccess(
      <String, Object?>{
        'runtimeValidation': runtimeValidationRecordJson(validation),
      },
      exitCode: validation.isValid ? 0 : 75,
    ),
    RuntimeValidationRuntimeNotFound(:final runtimeId) => jsonError(
      exitCode: 66,
      code: 'runtimeNotFound',
      message: 'Runtime not found.',
      extra: <String, Object?>{'runtimeId': runtimeId.value},
    ),
    RuntimeValidationFailed(:final message) => jsonError(
      exitCode: 75,
      code: 'runtimeValidationFailed',
      message: message,
    ),
  };
}

CliResult macosWineInstallJsonResult({
  required MacosWineInstallRequest request,
  required MacosWineInstaller? installer,
  required RuntimeInstallProgressSink? progressSink,
}) {
  if (installer == null) {
    return unavailableJsonError(
      code: 'macosWineInstallerUnavailable',
      subject: 'macOS Wine installer',
    );
  }

  return macosWineInstallCliResult(
    installer.install(
      request,
      progressSink: request.emitProgress ? progressSink : null,
    ),
  );
}

CliResult linuxWineInstallJsonResult({
  required LinuxWineInstallRequest request,
  required LinuxWineInstaller? installer,
  required RuntimeInstallProgressSink? progressSink,
}) {
  if (installer == null) {
    return unavailableJsonError(
      code: 'linuxWineInstallerUnavailable',
      subject: 'Linux Wine installer',
    );
  }

  return linuxWineInstallCliResult(
    installer.install(
      request,
      progressSink: request.emitProgress ? progressSink : null,
    ),
  );
}
