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
import 'cli_app_runtime_json.dart';
import 'cli_commands.dart';
import 'cli_json_helpers.dart';
import 'cli_location_winetricks_handlers.dart';
import 'cli_result_model.dart';
import 'cli_runtime_parsers.dart';
import 'cli_runtime_record_json.dart';
import 'cli_runtime_validation_json.dart';
import 'cli_update_json.dart';
import 'cli_update_runtime_results.dart';

CliCommandMatch handleRuntimeCommand(
  List<String> arguments,
  CliCommandContext context,
) {
  if (isJsonRuntimeListCommand(arguments)) {
    return CliCommandMatched(
      jsonSuccess(<String, Object?>{
        'runtimes': context.runtimeCatalog
            .listRuntimes()
            .map(runtimeRecordJson)
            .toList(growable: false),
      }),
    );
  }

  if (isJsonMacosSetupCheckCommand(arguments)) {
    final checker = context.macosSetupChecker;
    if (checker == null) {
      return CliCommandMatched(
        unavailableJsonError(
          code: 'macosSetupCheckerUnavailable',
          subject: 'macOS setup checker',
        ),
      );
    }

    return CliCommandMatched(switch (checker.check()) {
      MacosSetupCheckCompleted(:final status) => jsonSuccess(<String, Object?>{
        'macosSetup': macosSetupStatusJson(status),
      }),
      MacosSetupCheckFailed(:final message) => jsonError(
        exitCode: 75,
        code: 'macosSetupCheckFailed',
        message: message,
      ),
    });
  }

  final gptkWineInstallResult = parseJsonGptkWineInstallRequestOption(arguments)
      .match<CliCommandMatch>(() => const CliCommandNotMatched(), (
        gptkWineInstallRequest,
      ) {
        final installer = context.gptkWineInstaller;
        if (installer == null) {
          return CliCommandMatched(
            unavailableJsonError(
              code: 'gptkWineInstallerUnavailable',
              subject: 'GPTK/D3DMetal importer',
            ),
          );
        }

        return CliCommandMatched(switch (installer.install(
          gptkWineInstallRequest,
        )) {
          GptkWineInstallCompleted(:final record) => jsonSuccess(
            <String, Object?>{
              'gptkWineInstall': gptkWineInstallRecordJson(record),
            },
          ),
          GptkWineInstallFailed(:final message) => jsonError(
            exitCode: 75,
            code: 'gptkWineInstallFailed',
            message: message,
          ),
        });
      });
  switch (gptkWineInstallResult) {
    case CliCommandMatched():
      return gptkWineInstallResult;
    case CliCommandNotMatched():
  }

  final openUrlResult = parseJsonOpenUrlCommandOption(arguments)
      .match<CliCommandMatch>(() => const CliCommandNotMatched(), (openUrl) {
        return CliCommandMatched(
          openUrlJsonResult(openUrl, context.pathOpener),
        );
      });
  switch (openUrlResult) {
    case CliCommandMatched():
      return openUrlResult;
    case CliCommandNotMatched():
  }

  final runtimeUpdateCheckResult =
      parseJsonRuntimeIdCommandOption(
        arguments,
        'check-runtime-update',
      ).match<CliCommandMatch>(() => const CliCommandNotMatched(), (
        runtimeUpdateId,
      ) {
        return CliCommandMatched(
          runtimeUpdateCheckJsonResult(
            runtimeId: RuntimeId(runtimeUpdateId),
            runtimeUpdateChecker: context.runtimeUpdateChecker,
          ),
        );
      });
  switch (runtimeUpdateCheckResult) {
    case CliCommandMatched():
      return runtimeUpdateCheckResult;
    case CliCommandNotMatched():
  }

  final runtimeUpdateInstallResult =
      parseJsonRuntimeIdCommandOption(
        arguments,
        'install-runtime-update',
      ).match<CliCommandMatch>(() => const CliCommandNotMatched(), (
        runtimeUpdateInstallId,
      ) {
        return CliCommandMatched(
          installRuntimeUpdateJsonResult(
            runtimeId: RuntimeId(runtimeUpdateInstallId),
            runtimeUpdateChecker: context.runtimeUpdateChecker,
            macosWineInstaller: context.macosWineInstaller,
            linuxWineInstaller: context.linuxWineInstaller,
          ),
        );
      });
  switch (runtimeUpdateInstallResult) {
    case CliCommandMatched():
      return runtimeUpdateInstallResult;
    case CliCommandNotMatched():
  }

  final runtimeValidationResult =
      parseJsonRuntimeIdCommandOption(
        arguments,
        'validate-runtime',
      ).match<CliCommandMatch>(() => const CliCommandNotMatched(), (
        runtimeValidationId,
      ) {
        return CliCommandMatched(
          runtimeValidationJsonResult(
            runtimeId: RuntimeId(runtimeValidationId),
            runtimeValidator: context.runtimeValidator,
          ),
        );
      });
  switch (runtimeValidationResult) {
    case CliCommandMatched():
      return runtimeValidationResult;
    case CliCommandNotMatched():
  }

  final macosWineInstallResult =
      parseJsonMacosWineInstallRequestOption(arguments).match<CliCommandMatch>(
        () => const CliCommandNotMatched(),
        (macosWineInstallRequest) {
          return CliCommandMatched(
            macosWineInstallJsonResult(
              request: macosWineInstallRequest,
              installer: context.macosWineInstaller,
              progressSink: context.runtimeInstallProgressSink,
            ),
          );
        },
      );
  switch (macosWineInstallResult) {
    case CliCommandMatched():
      return macosWineInstallResult;
    case CliCommandNotMatched():
  }

  final linuxWineInstallResult =
      parseJsonLinuxWineInstallRequestOption(arguments).match<CliCommandMatch>(
        () => const CliCommandNotMatched(),
        (linuxWineInstallRequest) {
          return CliCommandMatched(
            linuxWineInstallJsonResult(
              request: linuxWineInstallRequest,
              installer: context.linuxWineInstaller,
              progressSink: context.runtimeInstallProgressSink,
            ),
          );
        },
      );
  switch (linuxWineInstallResult) {
    case CliCommandMatched():
      return linuxWineInstallResult;
    case CliCommandNotMatched():
  }

  return const CliCommandNotMatched();
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
