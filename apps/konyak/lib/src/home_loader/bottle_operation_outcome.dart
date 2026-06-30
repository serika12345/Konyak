import 'package:freezed_annotation/freezed_annotation.dart';

import '../bottles/bottle_summary.dart';

part 'bottle_operation_outcome.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleOperationOutcome with _$BottleOperationOutcome {
  const factory BottleOperationOutcome.completed(BottleSummary bottle) =
      CompletedBottleOperation;

  const factory BottleOperationOutcome.cancelled() = CancelledBottleOperation;

  const factory BottleOperationOutcome.failed() = FailedBottleOperation;

  const factory BottleOperationOutcome.unmounted() = UnmountedBottleOperation;
}
