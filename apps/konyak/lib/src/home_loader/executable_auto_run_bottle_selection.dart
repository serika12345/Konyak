import 'package:freezed_annotation/freezed_annotation.dart';

import '../app/utils/bottle_lists.dart';
import '../bottles/bottle_summary.dart';

part 'executable_auto_run_bottle_selection.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ExecutableAutoRunBottleSelection
    with _$ExecutableAutoRunBottleSelection {
  const factory ExecutableAutoRunBottleSelection.found(BottleSummary bottle) =
      FoundExecutableAutoRunBottle;

  const factory ExecutableAutoRunBottleSelection.missing(String bottleId) =
      MissingExecutableAutoRunBottle;

  const factory ExecutableAutoRunBottleSelection.disabled() =
      DisabledExecutableAutoRunBottle;
}

ExecutableAutoRunBottleSelection selectExecutableAutoRunBottle({
  required List<BottleSummary> bottles,
  required String bottleId,
}) {
  final normalizedBottleId = bottleId.trim();
  if (normalizedBottleId.isEmpty) {
    return const ExecutableAutoRunBottleSelection.disabled();
  }

  return switch (findBottleById(bottles, normalizedBottleId)) {
    BottleSelectionFound(:final bottle) =>
      ExecutableAutoRunBottleSelection.found(bottle),
    BottleSelectionMissing() => ExecutableAutoRunBottleSelection.missing(
      normalizedBottleId,
    ),
  };
}
