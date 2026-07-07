import 'package:freezed_annotation/freezed_annotation.dart';

import '../../cli/konyak_cli_client.dart';
import '../../runtimes/runtime_summary.dart';
import '../../settings/app_settings_summary.dart';
import '../../updates/update_check_summary.dart';
import '../app_platform.dart';
import '../runtime/runtime_platform.dart';
import '../utils/update_labels.dart';

part 'startup_update_checker.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class StartupKnownRuntimesState with _$StartupKnownRuntimesState {
  const factory StartupKnownRuntimesState.skipped() =
      StartupKnownRuntimesSkipped;

  factory StartupKnownRuntimesState.loaded(List<RuntimeSummary> runtimes) {
    return StartupKnownRuntimesState._loaded(List.unmodifiable(runtimes));
  }

  const factory StartupKnownRuntimesState._loaded(
    List<RuntimeSummary> runtimes,
  ) = StartupKnownRuntimesLoaded;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class StartupKonyakUpdateState with _$StartupKonyakUpdateState {
  const factory StartupKonyakUpdateState.unavailable() =
      StartupKonyakUpdateUnavailable;

  const factory StartupKonyakUpdateState.available(UpdateCheckSummary update) =
      StartupKonyakUpdateAvailable;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class StartupRuntimeUpdateState with _$StartupRuntimeUpdateState {
  const factory StartupRuntimeUpdateState.unavailable() =
      StartupRuntimeUpdateUnavailable;

  const factory StartupRuntimeUpdateState.available(UpdateCheckSummary update) =
      StartupRuntimeUpdateAvailable;
}

final class StartupUpdateCheckResult {
  StartupUpdateCheckResult({
    required List<String> availableUpdateLabels,
    required this.knownRuntimesState,
    required this.konyakUpdateState,
    required this.runtimeUpdateState,
  }) : availableUpdateLabels = List.unmodifiable(availableUpdateLabels);

  final List<String> availableUpdateLabels;
  final StartupKnownRuntimesState knownRuntimesState;
  final StartupKonyakUpdateState konyakUpdateState;
  final StartupRuntimeUpdateState runtimeUpdateState;
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
        knownRuntimesState: const StartupKnownRuntimesState.skipped(),
        konyakUpdateState: const StartupKonyakUpdateState.unavailable(),
        runtimeUpdateState: const StartupRuntimeUpdateState.unavailable(),
      );
    }

    final labels = <String>[];
    var konyakUpdateState = const StartupKonyakUpdateState.unavailable();
    var runtimeUpdateState = const StartupRuntimeUpdateState.unavailable();
    var knownRuntimesState = const StartupKnownRuntimesState.skipped();

    if (settings.automaticallyCheckForKonyakUpdates) {
      final result = await cliClient.checkKonyakUpdate();
      switch (result) {
        case LoadedUpdateCheck(:final update) when update.status == 'available':
          konyakUpdateState = StartupKonyakUpdateState.available(update);
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
          knownRuntimesState = StartupKnownRuntimesState.loaded(runtimes);
          switch (runtimeForPlatformSelection(platform, runtimes)) {
            case RuntimeForPlatformFound(:final runtime)
                when runtime.isInstalled == true:
              final updateResult = await cliClient.checkRuntimeUpdate(
                managedRuntime.runtimeId,
              );
              switch (updateResult) {
                case LoadedUpdateCheck(:final update)
                    when update.status == 'available':
                  runtimeUpdateState = StartupRuntimeUpdateState.available(
                    update,
                  );
                case LoadedUpdateCheck() || UpdateCheckLoadFailure():
                  break;
              }
            case RuntimeForPlatformFound() || RuntimeForPlatformMissing():
              break;
          }
        case RuntimeListLoadFailure():
          knownRuntimesState = StartupKnownRuntimesState.loaded(
            const <RuntimeSummary>[],
          );
      }
    }

    return StartupUpdateCheckResult(
      availableUpdateLabels: List.unmodifiable(labels),
      knownRuntimesState: knownRuntimesState,
      konyakUpdateState: konyakUpdateState,
      runtimeUpdateState: runtimeUpdateState,
    );
  }
}
