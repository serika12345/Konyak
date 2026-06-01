part of '../konyak_cli.dart';

CliResult? _handleAppCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  if (_isJsonAppUpdateCheckCommand(arguments)) {
    final checker = context.appUpdateChecker;
    if (checker == null) {
      return _unavailableJsonError(
        code: 'appUpdateCheckerUnavailable',
        subject: 'App update checker',
      );
    }

    return switch (checker.check()) {
      AppUpdateCheckCompleted(:final update) => _appUpdateJsonResult(update),
      AppUpdateCheckFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'appUpdateCheckFailed',
        message: message,
      ),
    };
  }

  if (_isJsonAppSettingsGetCommand(arguments)) {
    final repository = context.appSettingsRepository;
    if (repository == null) {
      return _appSettingsRepositoryUnavailableError();
    }

    return _appSettingsJsonResult(repository.read());
  }

  final appSettingsUpdate = _parseJsonAppSettingsUpdateRequest(arguments);
  if (appSettingsUpdate != null) {
    final repository = context.appSettingsRepository;
    if (repository == null) {
      return _appSettingsRepositoryUnavailableError();
    }

    return _appSettingsJsonResult(repository.write(appSettingsUpdate));
  }

  if (_isJsonAppUpdateInstallCommand(arguments)) {
    return _installAppUpdateJsonResult(
      appUpdateChecker: context.appUpdateChecker,
      appUpdateInstaller: context.appUpdateInstaller,
    );
  }

  return null;
}

CliResult? _handleHostIntegrationCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  if (!_isJsonLinuxFileAssociationInstallCommand(arguments)) {
    return null;
  }

  final result = _installLinuxFileAssociations(
    hostPlatform: context.programRunPlanner.hostPlatform,
    environment: context.programRunPlanner.environment,
  );
  return switch (result) {
    _LinuxFileAssociationsInstalled(
      :final desktopEntryPath,
      :final mimeAppsPath,
    ) =>
      _jsonSuccess(<String, Object?>{
        'linuxFileAssociations': <String, Object?>{
          'desktopEntryPath': desktopEntryPath,
          'mimeAppsPath': mimeAppsPath,
          'mimeTypes': _linuxExecutableMimeTypes,
        },
      }),
    _LinuxFileAssociationInstallFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'linuxFileAssociationInstallFailed',
      message: message,
    ),
  };
}

CliResult _appSettingsRepositoryUnavailableError() {
  return _unavailableJsonError(
    code: 'appSettingsRepositoryUnavailable',
    subject: 'App settings repository',
  );
}

CliResult? _handleRuntimeCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  if (_isJsonRuntimeListCommand(arguments)) {
    return _jsonSuccess(<String, Object?>{
      'runtimes': context.runtimeCatalog
          .listRuntimes()
          .map((runtime) => runtime.toJson())
          .toList(growable: false),
    });
  }

  if (_isJsonMacosSetupCheckCommand(arguments)) {
    final checker = context.macosSetupChecker;
    if (checker == null) {
      return _unavailableJsonError(
        code: 'macosSetupCheckerUnavailable',
        subject: 'macOS setup checker',
      );
    }

    return switch (checker.check()) {
      MacosSetupCheckCompleted(:final status) => _jsonSuccess(<String, Object?>{
        'macosSetup': status.toJson(),
      }),
      MacosSetupCheckFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'macosSetupCheckFailed',
        message: message,
      ),
    };
  }

  final gptkWineInstallRequest = _parseJsonGptkWineInstallRequest(arguments);
  if (gptkWineInstallRequest != null) {
    final installer = context.gptkWineInstaller;
    if (installer == null) {
      return _unavailableJsonError(
        code: 'gptkWineInstallerUnavailable',
        subject: 'GPTK-compatible Wine installer',
      );
    }

    return switch (installer.install(gptkWineInstallRequest)) {
      GptkWineInstallCompleted(:final record) => _jsonSuccess(<String, Object?>{
        'gptkWineInstall': record.toJson(),
      }),
      GptkWineInstallFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'gptkWineInstallFailed',
        message: message,
      ),
    };
  }

  final openUrl = _parseJsonOpenUrlCommand(arguments);
  if (openUrl != null) {
    return _openUrlJsonResult(openUrl, context.pathOpener);
  }

  final runtimeUpdateId = _parseJsonRuntimeIdCommand(
    arguments,
    'check-runtime-update',
  );
  if (runtimeUpdateId != null) {
    return _runtimeUpdateCheckJsonResult(
      runtimeId: runtimeUpdateId,
      runtimeUpdateChecker: context.runtimeUpdateChecker,
    );
  }

  final runtimeUpdateInstallId = _parseJsonRuntimeIdCommand(
    arguments,
    'install-runtime-update',
  );
  if (runtimeUpdateInstallId != null) {
    return _installRuntimeUpdateJsonResult(
      runtimeId: runtimeUpdateInstallId,
      runtimeUpdateChecker: context.runtimeUpdateChecker,
      macosWineInstaller: context.macosWineInstaller,
      linuxWineInstaller: context.linuxWineInstaller,
    );
  }

  final runtimeValidationId = _parseJsonRuntimeIdCommand(
    arguments,
    'validate-runtime',
  );
  if (runtimeValidationId != null) {
    return _runtimeValidationJsonResult(
      runtimeId: runtimeValidationId,
      runtimeValidator: context.runtimeValidator,
    );
  }

  final macosWineInstallRequest = _parseJsonMacosWineInstallRequest(arguments);
  if (macosWineInstallRequest != null) {
    return _macosWineInstallJsonResult(
      request: macosWineInstallRequest,
      installer: context.macosWineInstaller,
      progressSink: context.runtimeInstallProgressSink,
    );
  }

  final linuxWineInstallRequest = _parseJsonLinuxWineInstallRequest(arguments);
  if (linuxWineInstallRequest != null) {
    return _linuxWineInstallJsonResult(
      request: linuxWineInstallRequest,
      installer: context.linuxWineInstaller,
      progressSink: context.runtimeInstallProgressSink,
    );
  }

  return null;
}

CliResult _openUrlJsonResult(String openUrl, PathOpener? pathOpener) {
  if (pathOpener == null) {
    return _pathOpenerUnavailableError();
  }
  final openResult = pathOpener.openPath(openUrl);
  return switch (openResult) {
    PathOpenCompleted() => _jsonSuccess(<String, Object?>{
      'openedUrl': <String, Object?>{'url': openUrl},
    }),
    PathOpenFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'urlOpenFailed',
      message: message,
      extra: <String, Object?>{'url': openUrl},
    ),
  };
}

CliResult _runtimeUpdateCheckJsonResult({
  required String runtimeId,
  required RuntimeUpdateChecker? runtimeUpdateChecker,
}) {
  if (runtimeUpdateChecker == null) {
    return _unavailableJsonError(
      code: 'runtimeUpdateCheckerUnavailable',
      subject: 'Runtime update checker',
    );
  }

  return switch (runtimeUpdateChecker.check(runtimeId)) {
    RuntimeUpdateCheckCompleted(:final update) => _jsonSuccess(
      <String, Object?>{'runtimeUpdate': update.toJson()},
    ),
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

CliResult _runtimeValidationJsonResult({
  required String runtimeId,
  required RuntimeValidator? runtimeValidator,
}) {
  if (runtimeValidator == null) {
    return _unavailableJsonError(
      code: 'runtimeValidatorUnavailable',
      subject: 'Runtime validator',
    );
  }

  return switch (runtimeValidator.validate(runtimeId)) {
    RuntimeValidationCompleted(:final validation) => _jsonSuccess(
      <String, Object?>{'runtimeValidation': validation.toJson()},
      exitCode: validation.isValid ? 0 : 75,
    ),
    RuntimeValidationRuntimeNotFound(:final runtimeId) => _jsonError(
      exitCode: 66,
      code: 'runtimeNotFound',
      message: 'Runtime not found.',
      extra: <String, Object?>{'runtimeId': runtimeId},
    ),
    RuntimeValidationFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'runtimeValidationFailed',
      message: message,
    ),
  };
}

CliResult _macosWineInstallJsonResult({
  required MacosWineInstallRequest request,
  required MacosWineInstaller? installer,
  required RuntimeInstallProgressSink? progressSink,
}) {
  if (installer == null) {
    return _unavailableJsonError(
      code: 'macosWineInstallerUnavailable',
      subject: 'macOS Wine installer',
    );
  }

  return _macosWineInstallCliResult(
    installer.install(
      request,
      progressSink: request.emitProgress ? progressSink : null,
    ),
  );
}

CliResult _linuxWineInstallJsonResult({
  required LinuxWineInstallRequest request,
  required LinuxWineInstaller? installer,
  required RuntimeInstallProgressSink? progressSink,
}) {
  if (installer == null) {
    return _unavailableJsonError(
      code: 'linuxWineInstallerUnavailable',
      subject: 'Linux Wine installer',
    );
  }

  return _linuxWineInstallCliResult(
    installer.install(
      request,
      progressSink: request.emitProgress ? progressSink : null,
    ),
  );
}
