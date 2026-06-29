import '../domain/runtime/runtime_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../domain/update/update_records.dart';
import '../platform/linux/linux_wine_install_requests.dart';
import '../platform/linux/linux_wine_install_results.dart';
import '../platform/macos/macos_wine_install_requests.dart';
import '../platform/macos/macos_wine_install_results.dart';
import '../shared/model_constants.dart';
import 'cli_app_process_results.dart';
import 'cli_json_helpers.dart';
import 'cli_result_model.dart';
import 'cli_runtime_record_json.dart';

CliResult installAppUpdateJsonResult({
  required AppUpdateChecker? appUpdateChecker,
  required AppUpdateInstaller? appUpdateInstaller,
}) {
  final checker = appUpdateChecker;
  if (checker == null) {
    return unavailableJsonError(
      code: 'appUpdateCheckerUnavailable',
      subject: 'App update checker',
    );
  }

  final installer = appUpdateInstaller;
  if (installer == null) {
    return unavailableJsonError(
      code: 'appUpdateInstallerUnavailable',
      subject: 'App update installer',
    );
  }

  final updateResult = checker.check();
  return switch (updateResult) {
    AppUpdateCheckCompleted(:final update)
        when update.status.value != 'available' =>
      appUpdateInstallJsonResult(
        AppUpdateInstallRecord(
          appId: update.appId,
          status: UpdateInstallStatus('skipped'),
          currentVersion: update.currentVersion,
          installedVersion: update.currentVersion,
          archiveUrl: update.archiveUrl,
        ),
      ),
    AppUpdateCheckCompleted(:final update) => switch (installer.install(
      update,
    )) {
      AppUpdateInstallCompleted(:final install) => appUpdateInstallJsonResult(
        install,
      ),
      AppUpdateInstallFailed(:final message) => jsonError(
        exitCode: 75,
        code: 'appUpdateInstallFailed',
        message: message,
      ),
    },
    AppUpdateCheckFailed(:final message) => jsonError(
      exitCode: 75,
      code: 'appUpdateCheckFailed',
      message: message,
    ),
  };
}

CliResult installRuntimeUpdateJsonResult({
  required RuntimeId runtimeId,
  required RuntimeUpdateChecker? runtimeUpdateChecker,
  required MacosWineInstaller? macosWineInstaller,
  required LinuxWineInstaller? linuxWineInstaller,
}) {
  final checker = runtimeUpdateChecker;
  if (checker == null) {
    return unavailableJsonError(
      code: 'runtimeUpdateCheckerUnavailable',
      subject: 'Runtime update checker',
    );
  }

  final updateResult = checker.check(runtimeId);
  return switch (updateResult) {
    RuntimeUpdateCheckCompleted(:final update)
        when update.status.value != 'available' =>
      jsonError(
        exitCode: 65,
        code: 'runtimeUpdateNotAvailable',
        message: 'Runtime update is not available.',
        extra: <String, Object?>{'runtimeId': runtimeId.value},
      ),
    RuntimeUpdateCheckCompleted(:final update) => switch (runtimeId.value) {
      macosWineRuntimeId => switch (macosWineInstaller) {
        null => unavailableJsonError(
          code: 'macosWineInstallerUnavailable',
          subject: 'macOS Wine installer',
        ),
        final installer => switch (installer.install(
          macosWineInstallRequestForRuntimeUpdate(update),
        )) {
          MacosWineInstallCompleted(:final runtime) => runtimeJsonResult(
            runtime,
          ),
          MacosWineInstallFailed(:final message) => jsonError(
            exitCode: 75,
            code: 'macosWineInstallFailed',
            message: message,
          ),
        },
      },
      linuxWineRuntimeId => switch (linuxWineInstaller) {
        null => unavailableJsonError(
          code: 'linuxWineInstallerUnavailable',
          subject: 'Linux Wine installer',
        ),
        final installer => switch (installer.install(
          linuxWineInstallRequestForRuntimeUpdate(update),
        )) {
          LinuxWineInstallCompleted(:final runtime) => runtimeJsonResult(
            runtime,
          ),
          LinuxWineInstallFailed(:final message) => jsonError(
            exitCode: 75,
            code: 'linuxWineInstallFailed',
            message: message,
          ),
        },
      },
      _ => jsonError(
        exitCode: 65,
        code: 'unsupportedRuntimeUpdateInstall',
        message: 'Runtime update installation is not supported.',
        extra: <String, Object?>{'runtimeId': runtimeId.value},
      ),
    },
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

CliResult runtimeJsonResult(RuntimeRecord runtime) {
  return jsonSuccess(<String, Object?>{'runtime': runtimeRecordJson(runtime)});
}

CliResult macosWineInstallCliResult(MacosWineInstallResult installResult) {
  return switch (installResult) {
    MacosWineInstallCompleted(:final runtime) => runtimeJsonResult(runtime),
    MacosWineInstallFailed(:final message) => jsonError(
      exitCode: 75,
      code: 'macosWineInstallFailed',
      message: message,
    ),
  };
}

CliResult linuxWineInstallCliResult(LinuxWineInstallResult installResult) {
  return switch (installResult) {
    LinuxWineInstallCompleted(:final runtime) => runtimeJsonResult(runtime),
    LinuxWineInstallFailed(:final message) => jsonError(
      exitCode: 75,
      code: 'linuxWineInstallFailed',
      message: message,
    ),
  };
}

MacosWineInstallRequest macosWineInstallRequestForRuntimeUpdate(
  RuntimeUpdateRecord update,
) {
  return update.sourceManifestUrl.match(
    MacosWineInstallRequest.updateInstall,
    (sourceManifestUrl) => sourceManifestUrl.value.trim().isEmpty
        ? MacosWineInstallRequest.updateInstall()
        : MacosWineInstallRequest.updateInstall(
            sourceManifest: sourceManifestUrl.value,
            sourceManifestSignature: update.sourceManifestSignatureUrl
                .map((value) => value.value)
                .match(() => null, (value) => value),
          ),
  );
}

LinuxWineInstallRequest linuxWineInstallRequestForRuntimeUpdate(
  RuntimeUpdateRecord update,
) {
  return update.sourceManifestUrl.match(
    LinuxWineInstallRequest.updateInstall,
    (sourceManifestUrl) => sourceManifestUrl.value.trim().isEmpty
        ? LinuxWineInstallRequest.updateInstall()
        : LinuxWineInstallRequest.updateInstall(
            sourceManifest: sourceManifestUrl.value,
            sourceManifestSignature: update.sourceManifestSignatureUrl
                .map((value) => value.value)
                .match(() => null, (value) => value),
          ),
  );
}
