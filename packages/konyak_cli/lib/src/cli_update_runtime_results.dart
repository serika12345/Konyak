part of '../konyak_cli.dart';

CliResult _installAppUpdateJsonResult({
  required AppUpdateChecker? appUpdateChecker,
  required AppUpdateInstaller? appUpdateInstaller,
}) {
  final checker = appUpdateChecker;
  if (checker == null) {
    return _unavailableJsonError(
      code: 'appUpdateCheckerUnavailable',
      subject: 'App update checker',
    );
  }

  final installer = appUpdateInstaller;
  if (installer == null) {
    return _unavailableJsonError(
      code: 'appUpdateInstallerUnavailable',
      subject: 'App update installer',
    );
  }

  final updateResult = checker.check();
  return switch (updateResult) {
    AppUpdateCheckCompleted(:final update) when update.status != 'available' =>
      _appUpdateInstallJsonResult(
        AppUpdateInstallRecord(
          appId: update.appId,
          status: update.status,
          currentVersion: update.currentVersion,
          installedVersion: update.currentVersion,
          archiveUrl: update.archiveUrl,
        ),
      ),
    AppUpdateCheckCompleted(:final update) => switch (installer.install(
      update,
    )) {
      AppUpdateInstallCompleted(:final install) => _appUpdateInstallJsonResult(
        install,
      ),
      AppUpdateInstallFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'appUpdateInstallFailed',
        message: message,
      ),
    },
    AppUpdateCheckFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'appUpdateCheckFailed',
      message: message,
    ),
  };
}

CliResult _installRuntimeUpdateJsonResult({
  required String runtimeId,
  required RuntimeUpdateChecker? runtimeUpdateChecker,
  required MacosWineInstaller? macosWineInstaller,
  required LinuxWineInstaller? linuxWineInstaller,
}) {
  final checker = runtimeUpdateChecker;
  if (checker == null) {
    return _unavailableJsonError(
      code: 'runtimeUpdateCheckerUnavailable',
      subject: 'Runtime update checker',
    );
  }

  final updateResult = checker.check(runtimeId);
  return switch (updateResult) {
    RuntimeUpdateCheckCompleted(:final update)
        when update.status != 'available' =>
      _jsonError(
        exitCode: 65,
        code: 'runtimeUpdateNotAvailable',
        message: 'Runtime update is not available.',
        extra: <String, Object?>{'runtimeId': runtimeId},
      ),
    RuntimeUpdateCheckCompleted(:final update) => switch (runtimeId) {
      macosWineRuntimeId => switch (macosWineInstaller) {
        null => _unavailableJsonError(
          code: 'macosWineInstallerUnavailable',
          subject: 'macOS Wine installer',
        ),
        final installer => switch (installer.install(
          _macosWineInstallRequestForRuntimeUpdate(update),
        )) {
          MacosWineInstallCompleted(:final runtime) => _runtimeJsonResult(
            runtime,
          ),
          MacosWineInstallFailed(:final message) => _jsonError(
            exitCode: 75,
            code: 'macosWineInstallFailed',
            message: message,
          ),
        },
      },
      linuxWineRuntimeId => switch (linuxWineInstaller) {
        null => _unavailableJsonError(
          code: 'linuxWineInstallerUnavailable',
          subject: 'Linux Wine installer',
        ),
        final installer => switch (installer.install(
          _linuxWineInstallRequestForRuntimeUpdate(update),
        )) {
          LinuxWineInstallCompleted(:final runtime) => _runtimeJsonResult(
            runtime,
          ),
          LinuxWineInstallFailed(:final message) => _jsonError(
            exitCode: 75,
            code: 'linuxWineInstallFailed',
            message: message,
          ),
        },
      },
      _ => _jsonError(
        exitCode: 65,
        code: 'unsupportedRuntimeUpdateInstall',
        message: 'Runtime update installation is not supported.',
        extra: <String, Object?>{'runtimeId': runtimeId},
      ),
    },
    RuntimeUpdateRuntimeNotFound(:final runtimeId) => _jsonError(
      exitCode: 66,
      code: 'runtimeNotFound',
      message: 'Runtime not found.',
      extra: <String, Object?>{'runtimeId': runtimeId},
    ),
    RuntimeUpdateCheckFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'runtimeUpdateCheckFailed',
      message: message,
    ),
  };
}

CliResult _runtimeJsonResult(RuntimeRecord runtime) {
  return _jsonSuccess(<String, Object?>{'runtime': runtime.toJson()});
}

CliResult _macosWineInstallCliResult(MacosWineInstallResult installResult) {
  return switch (installResult) {
    MacosWineInstallCompleted(:final runtime) => _runtimeJsonResult(runtime),
    MacosWineInstallFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'macosWineInstallFailed',
      message: message,
    ),
  };
}

CliResult _linuxWineInstallCliResult(LinuxWineInstallResult installResult) {
  return switch (installResult) {
    LinuxWineInstallCompleted(:final runtime) => _runtimeJsonResult(runtime),
    LinuxWineInstallFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'linuxWineInstallFailed',
      message: message,
    ),
  };
}

MacosWineInstallRequest _macosWineInstallRequestForRuntimeUpdate(
  RuntimeUpdateRecord update,
) {
  final archiveUrl = update.archiveUrl.toNullable();
  final sourceManifestUrl = update.sourceManifestUrl.toNullable();
  if (sourceManifestUrl != null && sourceManifestUrl.trim().isNotEmpty) {
    return MacosWineInstallRequest.updateInstall(
      sourceManifest: sourceManifestUrl,
      sourceManifestSignature: update.sourceManifestSignatureUrl.toNullable(),
    );
  }
  if (archiveUrl != null && _isRuntimeStackSourceManifestSource(archiveUrl)) {
    return MacosWineInstallRequest.updateInstall(sourceManifest: archiveUrl);
  }

  return MacosWineInstallRequest.updateInstall(archiveUrl: archiveUrl);
}

LinuxWineInstallRequest _linuxWineInstallRequestForRuntimeUpdate(
  RuntimeUpdateRecord update,
) {
  final archiveUrl = update.archiveUrl.toNullable();
  final sourceManifestUrl = update.sourceManifestUrl.toNullable();
  if (sourceManifestUrl != null && sourceManifestUrl.trim().isNotEmpty) {
    return LinuxWineInstallRequest.updateInstall(
      sourceManifest: sourceManifestUrl,
      sourceManifestSignature: update.sourceManifestSignatureUrl.toNullable(),
    );
  }
  if (archiveUrl != null && _isRuntimeStackSourceManifestSource(archiveUrl)) {
    return LinuxWineInstallRequest.updateInstall(sourceManifest: archiveUrl);
  }

  return LinuxWineInstallRequest.updateInstall(archiveUrl: archiveUrl);
}

bool _isRuntimeStackSourceManifestSource(String source) {
  final normalized = source.trim().toLowerCase();
  return normalized.endsWith('.json') || normalized.contains('manifest');
}
