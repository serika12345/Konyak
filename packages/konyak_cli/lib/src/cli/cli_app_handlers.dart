import '../domain/update/update_records.dart';
import 'cli_app_process_parsers.dart';
import 'cli_app_process_results.dart';
import 'cli_commands.dart';
import 'cli_json_helpers.dart';
import 'cli_result_model.dart';
import 'cli_update_runtime_results.dart';

CliResult? handleAppCommand(List<String> arguments, CliCommandContext context) {
  if (isJsonAppUpdateCheckCommand(arguments)) {
    final checker = context.appUpdateChecker;
    if (checker == null) {
      return unavailableJsonError(
        code: 'appUpdateCheckerUnavailable',
        subject: 'App update checker',
      );
    }

    return switch (checker.check()) {
      AppUpdateCheckCompleted(:final update) => appUpdateJsonResult(update),
      AppUpdateCheckFailed(:final message) => jsonError(
        exitCode: 75,
        code: 'appUpdateCheckFailed',
        message: message,
      ),
    };
  }

  if (isJsonAppSettingsGetCommand(arguments)) {
    final repository = context.appSettingsRepository;
    if (repository == null) {
      return appSettingsRepositoryUnavailableError();
    }

    return repository.read().fold(
      appSettingsRepositoryFailureJsonResult,
      appSettingsJsonResult,
    );
  }

  final appSettingsUpdate = parseJsonAppSettingsUpdateRequest(arguments);
  if (appSettingsUpdate != null) {
    final repository = context.appSettingsRepository;
    if (repository == null) {
      return appSettingsRepositoryUnavailableError();
    }

    return repository
        .write(appSettingsUpdate)
        .fold(appSettingsRepositoryFailureJsonResult, appSettingsJsonResult);
  }

  if (isJsonAppUpdateInstallCommand(arguments)) {
    return installAppUpdateJsonResult(
      appUpdateChecker: context.appUpdateChecker,
      appUpdateInstaller: context.appUpdateInstaller,
    );
  }

  return null;
}

CliResult appSettingsRepositoryFailureJsonResult(String message) {
  return jsonError(
    exitCode: 74,
    code: 'appSettingsRepositoryError',
    message: message,
  );
}

CliResult appSettingsRepositoryUnavailableError() {
  return unavailableJsonError(
    code: 'appSettingsRepositoryUnavailable',
    subject: 'App settings repository',
  );
}
