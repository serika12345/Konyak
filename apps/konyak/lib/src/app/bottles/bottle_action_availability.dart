import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../bottles/bottle_summary.dart';
import 'bottle_action_target.dart';
import 'bottle_tool_action.dart';

part 'bottle_action_availability.freezed.dart';

typedef BottleToolCommandAction =
    void Function(BottleSummary bottle, String command);
typedef BottleToolLocationAction =
    void Function(BottleSummary bottle, String location);

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

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleToolsActionAvailability
    with _$BottleToolsActionAvailability {
  const factory BottleToolsActionAvailability.unavailable() =
      UnavailableBottleToolsActionAvailability;

  const factory BottleToolsActionAvailability.command(
    BottleToolCommandAction onRunCommand,
  ) = CommandBottleToolsActionAvailability;

  const factory BottleToolsActionAvailability.location(
    BottleToolLocationAction onOpenLocation,
  ) = LocationBottleToolsActionAvailability;

  const factory BottleToolsActionAvailability.commandAndLocation({
    required BottleToolCommandAction onRunCommand,
    required BottleToolLocationAction onOpenLocation,
  }) = CommandAndLocationBottleToolsActionAvailability;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleToolsTargetActionAvailability
    with _$BottleToolsTargetActionAvailability {
  const factory BottleToolsTargetActionAvailability.disabled() =
      DisabledBottleToolsTargetActionAvailability;

  const factory BottleToolsTargetActionAvailability.enabled({
    required BottleSummary bottle,
    required BottleToolsActionAvailability actions,
  }) = EnabledBottleToolsTargetActionAvailability;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleToolActionDispatch with _$BottleToolActionDispatch {
  const factory BottleToolActionDispatch.unavailable() =
      UnavailableBottleToolActionDispatch;

  const factory BottleToolActionDispatch.available(VoidCallback invoke) =
      AvailableBottleToolActionDispatch;
}

BottleSummaryActionAvailability bottleSummaryActionAvailabilityFromNullable(
  ValueChanged<BottleSummary>? action,
) {
  return switch (action) {
    null => const BottleSummaryActionAvailability.unavailable(),
    final action => BottleSummaryActionAvailability.available(action),
  };
}

BottleToolsActionAvailability bottleToolsActionAvailabilityFromNullable({
  required BottleToolCommandAction? onRunCommand,
  required BottleToolLocationAction? onOpenLocation,
}) {
  return switch ((onRunCommand, onOpenLocation)) {
    (final onRunCommand?, final onOpenLocation?) =>
      BottleToolsActionAvailability.commandAndLocation(
        onRunCommand: onRunCommand,
        onOpenLocation: onOpenLocation,
      ),
    (final onRunCommand?, null) => BottleToolsActionAvailability.command(
      onRunCommand,
    ),
    (null, final onOpenLocation?) => BottleToolsActionAvailability.location(
      onOpenLocation,
    ),
    (null, null) => const BottleToolsActionAvailability.unavailable(),
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

List<BottleToolActionKind> availableBottleToolActionKinds(
  BottleToolsActionAvailability actions,
) {
  return switch (actions) {
    UnavailableBottleToolsActionAvailability() =>
      const <BottleToolActionKind>[],
    CommandBottleToolsActionAvailability() => const [
      BottleToolActionKind.command,
    ],
    LocationBottleToolsActionAvailability() => const [
      BottleToolActionKind.location,
    ],
    CommandAndLocationBottleToolsActionAvailability() =>
      BottleToolActionKind.values,
  };
}

BottleToolsTargetActionAvailability resolveBottleToolsTargetAction({
  required BottleActionTarget target,
  required BottleToolsActionAvailability actions,
}) {
  return switch (target) {
    SelectedBottleActionTarget(:final bottle)
        when availableBottleToolActionKinds(actions).isNotEmpty =>
      BottleToolsTargetActionAvailability.enabled(
        bottle: bottle,
        actions: actions,
      ),
    NoBottleActionTarget() || SelectedBottleActionTarget() =>
      const BottleToolsTargetActionAvailability.disabled(),
  };
}

BottleToolActionDispatch resolveBottleToolActionDispatch({
  required BottleSummary bottle,
  required BottleToolsActionAvailability actions,
  required BottleToolAction action,
}) {
  return switch ((actions, action)) {
    (
      CommandBottleToolsActionAvailability(:final onRunCommand),
      CommandBottleToolAction(:final id),
    ) =>
      BottleToolActionDispatch.available(() => onRunCommand(bottle, id)),
    (
      LocationBottleToolsActionAvailability(:final onOpenLocation),
      LocationBottleToolAction(:final id),
    ) =>
      BottleToolActionDispatch.available(() => onOpenLocation(bottle, id)),
    (
      CommandAndLocationBottleToolsActionAvailability(:final onRunCommand),
      CommandBottleToolAction(:final id),
    ) =>
      BottleToolActionDispatch.available(() => onRunCommand(bottle, id)),
    (
      CommandAndLocationBottleToolsActionAvailability(:final onOpenLocation),
      LocationBottleToolAction(:final id),
    ) =>
      BottleToolActionDispatch.available(() => onOpenLocation(bottle, id)),
    _ => const BottleToolActionDispatch.unavailable(),
  };
}
