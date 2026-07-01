import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../bottles/bottle_summary.dart';
import 'bottle_action_target.dart';

part 'bottle_action_availability.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleSummaryActionAvailability
    with _$BottleSummaryActionAvailability {
  const factory BottleSummaryActionAvailability.unavailable() =
      UnavailableBottleSummaryActionAvailability;

  const factory BottleSummaryActionAvailability.available(
    ValueChanged<BottleSummary> invoke,
  ) = AvailableBottleSummaryActionAvailability;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleTargetActionAvailability
    with _$BottleTargetActionAvailability {
  const factory BottleTargetActionAvailability.disabled() =
      DisabledBottleTargetActionAvailability;

  const factory BottleTargetActionAvailability.enabled(VoidCallback invoke) =
      EnabledBottleTargetActionAvailability;
}

BottleSummaryActionAvailability bottleSummaryActionAvailabilityFromNullable(
  ValueChanged<BottleSummary>? action,
) {
  return switch (action) {
    null => const BottleSummaryActionAvailability.unavailable(),
    final action => BottleSummaryActionAvailability.available(action),
  };
}

BottleTargetActionAvailability resolveBottleTargetAction({
  required BottleActionTarget target,
  required BottleSummaryActionAvailability action,
}) {
  return switch ((target, action)) {
    (
      SelectedBottleActionTarget(:final bottle),
      AvailableBottleSummaryActionAvailability(:final invoke),
    ) =>
      BottleTargetActionAvailability.enabled(() => invoke(bottle)),
    _ => const BottleTargetActionAvailability.disabled(),
  };
}
