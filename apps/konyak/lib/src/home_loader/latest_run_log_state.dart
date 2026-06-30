import 'package:freezed_annotation/freezed_annotation.dart';

part 'latest_run_log_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class LatestRunLogState with _$LatestRunLogState {
  const factory LatestRunLogState.available(String path) =
      AvailableLatestRunLog;

  const factory LatestRunLogState.unavailable() = UnavailableLatestRunLog;
}

LatestRunLogState latestRunLogStateFromPath(String path) {
  return switch (path.trim()) {
    final logPath when logPath.isNotEmpty => LatestRunLogState.available(
      logPath,
    ),
    _ => const LatestRunLogState.unavailable(),
  };
}
