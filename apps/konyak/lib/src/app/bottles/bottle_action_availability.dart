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
typedef PinnedProgramAction =
    void Function(BottleSummary bottle, PinnedProgramSummary program);
typedef ProgramPathAction =
    void Function(BottleSummary bottle, String programPath);

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
sealed class PinnedProgramActionAvailability
    with _$PinnedProgramActionAvailability {
  const factory PinnedProgramActionAvailability.unavailable() =
      UnavailablePinnedProgramActionAvailability;

  const factory PinnedProgramActionAvailability.available(
    PinnedProgramAction invoke,
  ) = AvailablePinnedProgramActionAvailability;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramPathActionAvailability
    with _$ProgramPathActionAvailability {
  const factory ProgramPathActionAvailability.unavailable() =
      UnavailableProgramPathActionAvailability;

  const factory ProgramPathActionAvailability.available(
    ProgramPathAction invoke,
  ) = AvailableProgramPathActionAvailability;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleCommandActionAvailability
    with _$BottleCommandActionAvailability {
  const factory BottleCommandActionAvailability.unavailable() =
      UnavailableBottleCommandActionAvailability;

  const factory BottleCommandActionAvailability.available(
    BottleToolCommandAction invoke,
  ) = AvailableBottleCommandActionAvailability;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleLocationActionAvailability
    with _$BottleLocationActionAvailability {
  const factory BottleLocationActionAvailability.unavailable() =
      UnavailableBottleLocationActionAvailability;

  const factory BottleLocationActionAvailability.available(
    BottleToolLocationAction invoke,
  ) = AvailableBottleLocationActionAvailability;
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

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class BottleLocationActionDispatch with _$BottleLocationActionDispatch {
  const factory BottleLocationActionDispatch.unavailable() =
      UnavailableBottleLocationActionDispatch;

  const factory BottleLocationActionDispatch.available(VoidCallback invoke) =
      AvailableBottleLocationActionDispatch;
}

BottleSummaryActionAvailability bottleSummaryActionAvailabilityFromNullable(
  ValueChanged<BottleSummary>? action,
) {
  return switch (action) {
    null => const BottleSummaryActionAvailability.unavailable(),
    final action => BottleSummaryActionAvailability.available(action),
  };
}

PinnedProgramActionAvailability pinnedProgramActionAvailabilityFromNullable(
  PinnedProgramAction? action,
) {
  return switch (action) {
    null => const PinnedProgramActionAvailability.unavailable(),
    final action => PinnedProgramActionAvailability.available(action),
  };
}

ProgramPathActionAvailability programPathActionAvailabilityFromNullable(
  ProgramPathAction? action,
) {
  return switch (action) {
    null => const ProgramPathActionAvailability.unavailable(),
    final action => ProgramPathActionAvailability.available(action),
  };
}

BottleCommandActionAvailability bottleCommandActionAvailabilityFromNullable(
  BottleToolCommandAction? action,
) {
  return switch (action) {
    null => const BottleCommandActionAvailability.unavailable(),
    final action => BottleCommandActionAvailability.available(action),
  };
}

BottleLocationActionAvailability bottleLocationActionAvailabilityFromNullable(
  BottleToolLocationAction? action,
) {
  return switch (action) {
    null => const BottleLocationActionAvailability.unavailable(),
    final action => BottleLocationActionAvailability.available(action),
  };
}

BottleToolsActionAvailability bottleToolsActionAvailabilityFromNullable({
  required BottleToolCommandAction? onRunCommand,
  required BottleToolLocationAction? onOpenLocation,
}) {
  return bottleToolsActionAvailabilityFromActions(
    commandAction: bottleCommandActionAvailabilityFromNullable(onRunCommand),
    locationAction: bottleLocationActionAvailabilityFromNullable(
      onOpenLocation,
    ),
  );
}

BottleToolsActionAvailability bottleToolsActionAvailabilityFromActions({
  required BottleCommandActionAvailability commandAction,
  required BottleLocationActionAvailability locationAction,
}) {
  return switch ((commandAction, locationAction)) {
    (
      AvailableBottleCommandActionAvailability(:final invoke),
      AvailableBottleLocationActionAvailability(invoke: final onOpenLocation),
    ) =>
      BottleToolsActionAvailability.commandAndLocation(
        onRunCommand: invoke,
        onOpenLocation: onOpenLocation,
      ),
    (AvailableBottleCommandActionAvailability(:final invoke), _) =>
      BottleToolsActionAvailability.command(invoke),
    (_, AvailableBottleLocationActionAvailability(:final invoke)) =>
      BottleToolsActionAvailability.location(invoke),
    _ => const BottleToolsActionAvailability.unavailable(),
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

BottleTargetActionAvailability resolveBottleSummaryAction({
  required BottleSummary bottle,
  required BottleSummaryActionAvailability action,
}) {
  return resolveBottleTargetAction(
    target: BottleActionTarget.bottle(bottle),
    action: action,
  );
}

BottleSummaryActionAvailability firstAvailableBottleSummaryAction({
  required BottleSummaryActionAvailability preferred,
  required BottleSummaryActionAvailability fallback,
}) {
  return switch (preferred) {
    AvailableBottleSummaryActionAvailability() => preferred,
    UnavailableBottleSummaryActionAvailability() => fallback,
  };
}

BottleTargetActionAvailability resolvePinnedProgramAction({
  required BottleSummary bottle,
  required PinnedProgramSummary program,
  required PinnedProgramActionAvailability action,
}) {
  return switch (action) {
    AvailablePinnedProgramActionAvailability(:final invoke) =>
      BottleTargetActionAvailability.enabled(() => invoke(bottle, program)),
    UnavailablePinnedProgramActionAvailability() =>
      const BottleTargetActionAvailability.disabled(),
  };
}

BottleTargetActionAvailability resolveProgramPathAction({
  required BottleSummary bottle,
  required PinnedProgramSummary program,
  required ProgramPathActionAvailability action,
}) {
  return switch (action) {
    AvailableProgramPathActionAvailability(:final invoke) =>
      BottleTargetActionAvailability.enabled(
        () => invoke(bottle, program.path),
      ),
    UnavailableProgramPathActionAvailability() =>
      const BottleTargetActionAvailability.disabled(),
  };
}

BottleLocationActionDispatch resolveBottleLocationAction({
  required BottleSummary bottle,
  required String location,
  required BottleLocationActionAvailability action,
}) {
  return switch (action) {
    AvailableBottleLocationActionAvailability(:final invoke) =>
      BottleLocationActionDispatch.available(() => invoke(bottle, location)),
    UnavailableBottleLocationActionAvailability() =>
      const BottleLocationActionDispatch.unavailable(),
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
