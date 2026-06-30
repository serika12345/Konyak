import 'package:freezed_annotation/freezed_annotation.dart';

import '../../runtimes/runtime_summary.dart';
import '../app_platform.dart';
import '../runtime/runtime_platform.dart';

part 'runtime_capabilities_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeCapabilitiesState with _$RuntimeCapabilitiesState {
  const factory RuntimeCapabilitiesState.loading() = LoadingRuntimeCapabilities;

  const factory RuntimeCapabilitiesState.unavailable() =
      UnavailableRuntimeCapabilities;

  const factory RuntimeCapabilitiesState.available(RuntimeSummary runtime) =
      AvailableRuntimeCapabilities;
}

RuntimeCapabilitiesState runtimeCapabilitiesStateForPlatform({
  required KonyakPlatform platform,
  required bool isLoading,
  required List<RuntimeSummary> runtimes,
}) {
  return switch (isLoading) {
    true => const RuntimeCapabilitiesState.loading(),
    false => switch (runtimeForPlatformSelection(platform, runtimes)) {
      RuntimeForPlatformFound(:final runtime) =>
        RuntimeCapabilitiesState.available(runtime),
      RuntimeForPlatformMissing() =>
        const RuntimeCapabilitiesState.unavailable(),
    },
  };
}
