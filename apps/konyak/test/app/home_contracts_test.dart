import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/app_platform.dart';
import 'package:konyak/src/app/home/home_contracts.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';

void main() {
  test('home view state snapshots mutable collections at the UI boundary', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final bottles = <BottleSummary>[bottle];
    final programSettings = <String, ProgramSettingsSummary>{
      'steam:/games/setup.exe': ProgramSettingsSummary(locale: 'ja_JP.UTF-8'),
    };
    final loadingProgramSettings = <String>{'steam:/games/setup.exe'};
    final pendingRuntimeSettingsControls = <String, String>{'steam': 'dxvk'};

    final state = KonyakHomeViewState(
      platform: KonyakPlatform.macos,
      bottles: bottles,
      programSettings: programSettings,
      loadingProgramSettings: loadingProgramSettings,
      pendingRuntimeSettingsControls: pendingRuntimeSettingsControls,
    );

    bottles.clear();
    programSettings.clear();
    loadingProgramSettings.clear();
    pendingRuntimeSettingsControls.clear();

    expect(state.bottles, [bottle]);
    expect(state.programSettings.keys, ['steam:/games/setup.exe']);
    expect(state.loadingProgramSettings, {'steam:/games/setup.exe'});
    expect(state.pendingRuntimeSettingsControls, {'steam': 'dxvk'});
    expect(state.bottles.clear, throwsUnsupportedError);
    expect(state.programSettings.clear, throwsUnsupportedError);
    expect(state.loadingProgramSettings.clear, throwsUnsupportedError);
    expect(state.pendingRuntimeSettingsControls.clear, throwsUnsupportedError);
  });

  test(
    'home detail state derives selected program settings by bottle and path',
    () {
      final bottle = _bottle(
        id: 'steam',
        name: 'Steam',
        pinnedPrograms: const <PinnedProgramSummary>[
          PinnedProgramSummary(
            name: 'Setup',
            path: '/games/setup.exe',
            removable: true,
          ),
        ],
      );
      final state = KonyakHomeViewState(
        platform: KonyakPlatform.macos,
        bottles: [bottle],
        programSettings: <String, ProgramSettingsSummary>{
          'steam:/games/setup.exe': ProgramSettingsSummary(
            locale: 'ja_JP.UTF-8',
          ),
        },
        loadingProgramSettings: const <String>{'steam:/games/setup.exe'},
        pendingRuntimeSettingsControls: const <String, String>{'steam': 'dxvk'},
      );
      final detailState = state.detailStateFor(
        bottle: bottle,
        detailMode: BottleDetailMode.programConfiguration,
        selectedProgram: bottle.pinnedPrograms.first,
        isBottleNavigationLocked: true,
      );

      expect(detailState.programSettings?.locale, 'ja_JP.UTF-8');
      expect(detailState.isProgramSettingsLoading, isTrue);
      expect(detailState.pendingRuntimeSettingsControlKey, 'dxvk');
      expect(detailState.isBottleNavigationLocked, isTrue);
    },
  );
}

BottleSummary _bottle({
  required String id,
  required String name,
  Iterable<PinnedProgramSummary> pinnedPrograms =
      const <PinnedProgramSummary>[],
}) {
  return BottleSummary(
    id: id,
    name: name,
    path: '/bottles/$id',
    windowsVersion: 'win10',
    pinnedPrograms: pinnedPrograms,
  );
}
