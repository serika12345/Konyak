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

CliResult _appSettingsRepositoryUnavailableError() {
  return _unavailableJsonError(
    code: 'appSettingsRepositoryUnavailable',
    subject: 'App settings repository',
  );
}
