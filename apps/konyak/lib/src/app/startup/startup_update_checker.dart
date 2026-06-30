import '../../cli/konyak_cli_client.dart';
import '../../runtimes/runtime_summary.dart';
import '../../settings/app_settings_summary.dart';
import '../../updates/update_check_summary.dart';
import '../app_platform.dart';
import '../runtime/runtime_platform.dart';
import '../utils/update_labels.dart';

final class StartupUpdateCheckResult {
  StartupUpdateCheckResult({
    required List<String> availableUpdateLabels,
    required List<RuntimeSummary>? knownRuntimes,
    this.konyakUpdate,
  }) : availableUpdateLabels = List.unmodifiable(availableUpdateLabels),
       knownRuntimes = knownRuntimes == null
           ? null
           : List.unmodifiable(knownRuntimes);

  final List<String> availableUpdateLabels;
  final List<RuntimeSummary>? knownRuntimes;
  final UpdateCheckSummary? konyakUpdate;
}

final class StartupUpdateChecker {
  const StartupUpdateChecker({required this.platform, required this.cliClient});

  final KonyakPlatform platform;
  final KonyakCliClient cliClient;

  Future<StartupUpdateCheckResult> check(AppSettingsSummary settings) async {
    if (!settings.automaticallyCheckForKonyakUpdates &&
        !settings.automaticallyCheckForWineUpdates) {
      return StartupUpdateCheckResult(
        availableUpdateLabels: <String>[],
        knownRuntimes: null,
      );
    }

    final labels = <String>[];
    UpdateCheckSummary? konyakUpdate;
    List<RuntimeSummary>? knownRuntimes;

    if (settings.automaticallyCheckForKonyakUpdates) {
      final result = await cliClient.checkKonyakUpdate();
      switch (result) {
        case LoadedUpdateCheck(:final update) when update.status == 'available':
          konyakUpdate = update;
          labels.add(updateCheckLabel(update, 'Konyak'));
        case LoadedUpdateCheck() || UpdateCheckLoadFailure():
          break;
      }
    }

    final managedRuntime = managedRuntimePlatform(platform);
    if (settings.automaticallyCheckForWineUpdates) {
      final runtimeResult = await cliClient.listKnownRuntimes();
      switch (runtimeResult) {
        case LoadedRuntimeList(:final runtimes):
          knownRuntimes = runtimes;
          switch (runtimeForPlatformSelection(platform, runtimes)) {
            case RuntimeForPlatformFound(:final runtime)
                when runtime.isInstalled == true:
              final updateResult = await cliClient.checkRuntimeUpdate(
                managedRuntime.runtimeId,
              );
              switch (updateResult) {
                case LoadedUpdateCheck(:final update)
                    when update.status == 'available':
                  labels.add(
                    updateCheckLabel(update, managedRuntime.displayName),
                  );
                case LoadedUpdateCheck() || UpdateCheckLoadFailure():
                  break;
              }
            case RuntimeForPlatformFound() || RuntimeForPlatformMissing():
              break;
          }
        case RuntimeListLoadFailure():
          knownRuntimes = const <RuntimeSummary>[];
      }
    }

    return StartupUpdateCheckResult(
      availableUpdateLabels: List.unmodifiable(labels),
      knownRuntimes: knownRuntimes,
      konyakUpdate: konyakUpdate,
    );
  }
}
