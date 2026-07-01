import 'package:freezed_annotation/freezed_annotation.dart';

import '../../bottles/bottle_summary.dart';

part 'runtime_settings_change.freezed.dart';

typedef RuntimeSettingsChanged =
    void Function(
      BottleSummary bottle,
      BottleRuntimeSettingsSummary runtimeSettings,
      String controlKey,
    );
typedef RuntimeSettingsChangeDispatchCallback = void Function();

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeSettingsChangeAvailability
    with _$RuntimeSettingsChangeAvailability {
  const factory RuntimeSettingsChangeAvailability.unavailable() =
      UnavailableRuntimeSettingsChangeAvailability;

  const factory RuntimeSettingsChangeAvailability.available(
    RuntimeSettingsChanged invoke,
  ) = AvailableRuntimeSettingsChangeAvailability;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeSettingsChangeDispatch
    with _$RuntimeSettingsChangeDispatch {
  const factory RuntimeSettingsChangeDispatch.unavailable() =
      UnavailableRuntimeSettingsChangeDispatch;

  const factory RuntimeSettingsChangeDispatch.available(
    RuntimeSettingsChangeDispatchCallback invoke,
  ) = AvailableRuntimeSettingsChangeDispatch;
}

RuntimeSettingsChangeAvailability runtimeSettingsChangeAvailabilityFromNullable(
  RuntimeSettingsChanged? action,
) {
  return switch (action) {
    null => const RuntimeSettingsChangeAvailability.unavailable(),
    final action => RuntimeSettingsChangeAvailability.available(action),
  };
}

bool canChangeRuntimeSettings(RuntimeSettingsChangeAvailability action) {
  return switch (action) {
    AvailableRuntimeSettingsChangeAvailability() => true,
    UnavailableRuntimeSettingsChangeAvailability() => false,
  };
}

RuntimeSettingsChangeDispatch resolveRuntimeSettingsChange({
  required BottleSummary bottle,
  required BottleRuntimeSettingsSummary runtimeSettings,
  required String controlKey,
  required RuntimeSettingsChangeAvailability action,
}) {
  return switch (action) {
    AvailableRuntimeSettingsChangeAvailability(:final invoke) =>
      RuntimeSettingsChangeDispatch.available(
        () => invoke(bottle, runtimeSettings, controlKey),
      ),
    UnavailableRuntimeSettingsChangeAvailability() =>
      const RuntimeSettingsChangeDispatch.unavailable(),
  };
}
