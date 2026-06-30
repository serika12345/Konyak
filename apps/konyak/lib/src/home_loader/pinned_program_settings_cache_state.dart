import 'package:freezed_annotation/freezed_annotation.dart';

import '../bottles/bottle_summary.dart';

part 'pinned_program_settings_cache_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class PinnedProgramSettingsCacheState
    with _$PinnedProgramSettingsCacheState {
  const PinnedProgramSettingsCacheState._();

  const factory PinnedProgramSettingsCacheState.empty() =
      EmptyPinnedProgramSettingsCacheState;

  factory PinnedProgramSettingsCacheState.cached({
    Map<String, ProgramSettingsSummary> settings =
        const <String, ProgramSettingsSummary>{},
    Set<String> loadingKeys = const <String>{},
  }) {
    return settings.isEmpty && loadingKeys.isEmpty
        ? const PinnedProgramSettingsCacheState.empty()
        : PinnedProgramSettingsCacheState._cached(
            settings: Map.unmodifiable(settings),
            loadingKeys: Set.unmodifiable(loadingKeys),
          );
  }

  const factory PinnedProgramSettingsCacheState._cached({
    required Map<String, ProgramSettingsSummary> settings,
    required Set<String> loadingKeys,
  }) = CachedPinnedProgramSettingsCacheState;
}

PinnedProgramSettingsCacheState startLoadingPinnedProgramSettings({
  required PinnedProgramSettingsCacheState state,
  required String key,
}) {
  return PinnedProgramSettingsCacheState.cached(
    settings: pinnedProgramSettingsSnapshot(state),
    loadingKeys: {...loadingPinnedProgramSettingsKeysSnapshot(state), key},
  );
}

PinnedProgramSettingsCacheState storeLoadedPinnedProgramSettings({
  required PinnedProgramSettingsCacheState state,
  required String key,
  required ProgramSettingsSummary settings,
}) {
  return PinnedProgramSettingsCacheState.cached(
    settings: {...pinnedProgramSettingsSnapshot(state), key: settings},
    loadingKeys: _withoutLoadingKey(state: state, key: key),
  );
}

PinnedProgramSettingsCacheState savePinnedProgramSettings({
  required PinnedProgramSettingsCacheState state,
  required String key,
  required ProgramSettingsSummary settings,
}) {
  return PinnedProgramSettingsCacheState.cached(
    settings: {...pinnedProgramSettingsSnapshot(state), key: settings},
    loadingKeys: loadingPinnedProgramSettingsKeysSnapshot(state),
  );
}

PinnedProgramSettingsCacheState removePinnedProgramSettings({
  required PinnedProgramSettingsCacheState state,
  required String key,
}) {
  return PinnedProgramSettingsCacheState.cached(
    settings: Map.fromEntries(
      pinnedProgramSettingsSnapshot(
        state,
      ).entries.where((entry) => entry.key != key),
    ),
    loadingKeys: _withoutLoadingKey(state: state, key: key),
  );
}

bool isLoadingPinnedProgramSettings({
  required PinnedProgramSettingsCacheState state,
  required String key,
}) {
  return switch (state) {
    EmptyPinnedProgramSettingsCacheState() => false,
    CachedPinnedProgramSettingsCacheState(:final loadingKeys) =>
      loadingKeys.contains(key),
  };
}

Map<String, ProgramSettingsSummary> pinnedProgramSettingsSnapshot(
  PinnedProgramSettingsCacheState state,
) {
  return switch (state) {
    EmptyPinnedProgramSettingsCacheState() =>
      Map<String, ProgramSettingsSummary>.unmodifiable(const {}),
    CachedPinnedProgramSettingsCacheState(:final settings) => settings,
  };
}

Set<String> loadingPinnedProgramSettingsKeysSnapshot(
  PinnedProgramSettingsCacheState state,
) {
  return switch (state) {
    EmptyPinnedProgramSettingsCacheState() => Set<String>.unmodifiable(
      const {},
    ),
    CachedPinnedProgramSettingsCacheState(:final loadingKeys) => loadingKeys,
  };
}

Set<String> _withoutLoadingKey({
  required PinnedProgramSettingsCacheState state,
  required String key,
}) {
  return Set.unmodifiable(
    loadingPinnedProgramSettingsKeysSnapshot(
      state,
    ).where((loadingKey) => loadingKey != key),
  );
}
