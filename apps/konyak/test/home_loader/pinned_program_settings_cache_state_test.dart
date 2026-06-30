import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';
import 'package:konyak/src/home_loader/pinned_program_settings_cache_state.dart';

void main() {
  test('models an empty pinned program settings cache explicitly', () {
    const state = PinnedProgramSettingsCacheState.empty();

    expect(pinnedProgramSettingsSnapshot(state), isEmpty);
    expect(loadingPinnedProgramSettingsKeysSnapshot(state), isEmpty);
    expect(
      isLoadingPinnedProgramSettings(state: state, key: 'steam:/setup.exe'),
      isFalse,
    );
  });

  test('starts and finishes pinned program settings loads immutably', () {
    final loading = startLoadingPinnedProgramSettings(
      state: const PinnedProgramSettingsCacheState.empty(),
      key: 'steam:/setup.exe',
    );

    expect(pinnedProgramSettingsSnapshot(loading), isEmpty);
    expect(loadingPinnedProgramSettingsKeysSnapshot(loading), {
      'steam:/setup.exe',
    });
    expect(
      isLoadingPinnedProgramSettings(state: loading, key: 'steam:/setup.exe'),
      isTrue,
    );

    final duplicateLoading = startLoadingPinnedProgramSettings(
      state: loading,
      key: 'steam:/setup.exe',
    );

    expect(loadingPinnedProgramSettingsKeysSnapshot(duplicateLoading), {
      'steam:/setup.exe',
    });

    final loaded = storeLoadedPinnedProgramSettings(
      state: duplicateLoading,
      key: 'steam:/setup.exe',
      settings: ProgramSettingsSummary(locale: 'ja_JP.UTF-8'),
    );

    expect(loadingPinnedProgramSettingsKeysSnapshot(loaded), isEmpty);
    expect(pinnedProgramSettingsSnapshot(loaded).keys, ['steam:/setup.exe']);
    expect(_singleSettings(loaded).locale, 'ja_JP.UTF-8');

    final loadingAgain = startLoadingPinnedProgramSettings(
      state: loaded,
      key: 'steam:/setup.exe',
    );

    expect(pinnedProgramSettingsSnapshot(loadingAgain).keys, [
      'steam:/setup.exe',
    ]);
    expect(_singleSettings(loadingAgain).locale, 'ja_JP.UTF-8');
    expect(loadingPinnedProgramSettingsKeysSnapshot(loadingAgain), {
      'steam:/setup.exe',
    });

    final removed = removePinnedProgramSettings(
      state: loadingAgain,
      key: 'steam:/setup.exe',
    );

    expect(pinnedProgramSettingsSnapshot(removed), isEmpty);
    expect(loadingPinnedProgramSettingsKeysSnapshot(removed), isEmpty);
    switch (removed) {
      case EmptyPinnedProgramSettingsCacheState():
        break;
      case CachedPinnedProgramSettingsCacheState():
        fail('removing the final cached/loading key must return empty state');
    }
  });

  test('saves pinned program settings without changing loading keys', () {
    final loading = startLoadingPinnedProgramSettings(
      state: const PinnedProgramSettingsCacheState.empty(),
      key: 'steam:/setup.exe',
    );

    final saved = savePinnedProgramSettings(
      state: loading,
      key: 'steam:/setup.exe',
      settings: ProgramSettingsSummary(arguments: '--lang ja'),
    );

    expect(pinnedProgramSettingsSnapshot(saved).keys, ['steam:/setup.exe']);
    expect(_singleSettings(saved).arguments, '--lang ja');
    expect(loadingPinnedProgramSettingsKeysSnapshot(saved), {
      'steam:/setup.exe',
    });
  });

  test('takes immutable snapshots of source cache collections', () {
    final sourceSettings = <String, ProgramSettingsSummary>{
      'steam:/setup.exe': ProgramSettingsSummary(locale: 'ja_JP.UTF-8'),
    };
    final sourceLoadingKeys = <String>{'steam:/setup.exe'};
    final state = PinnedProgramSettingsCacheState.cached(
      settings: sourceSettings,
      loadingKeys: sourceLoadingKeys,
    );

    sourceSettings['battle-net:/setup.exe'] = ProgramSettingsSummary(
      locale: 'en_US.UTF-8',
    );
    sourceLoadingKeys.add('battle-net:/setup.exe');

    expect(pinnedProgramSettingsSnapshot(state).keys, ['steam:/setup.exe']);
    expect(_singleSettings(state).locale, 'ja_JP.UTF-8');
    expect(loadingPinnedProgramSettingsKeysSnapshot(state), {
      'steam:/setup.exe',
    });
    expect(pinnedProgramSettingsSnapshot(state).clear, throwsUnsupportedError);
    expect(
      loadingPinnedProgramSettingsKeysSnapshot(state).clear,
      throwsUnsupportedError,
    );
  });
}

ProgramSettingsSummary _singleSettings(PinnedProgramSettingsCacheState state) {
  final settings = pinnedProgramSettingsSnapshot(state).values.toList();
  expect(settings, hasLength(1));
  return settings.single;
}
