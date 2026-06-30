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

  test('models bottle list loading and failures explicitly', () {
    expect(isBottleListLoading(const BottleListLoadState.loading()), isTrue);
    expect(isBottleListLoading(const BottleListLoadState.loaded()), isFalse);
    expect(
      isBottleListLoading(
        const BottleListLoadState.failed('list-bottles failed'),
      ),
      isFalse,
    );
  });

  test('models runtime settings control updates explicitly', () {
    const idle = RuntimeSettingsControlState.idle();
    const updating = RuntimeSettingsControlState.updating('dxvk');

    expect(hasPendingRuntimeSettings(idle), isFalse);
    expect(hasPendingRuntimeSettings(updating), isTrue);
    expect(
      isRuntimeSettingsControlUpdating(state: updating, controlKey: 'dxvk'),
      isTrue,
    );
    expect(
      isRuntimeSettingsControlUpdating(state: updating, controlKey: 'retina'),
      isFalse,
    );
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
        runtimeCapabilitiesState: const RuntimeCapabilitiesState.loading(),
        bottleListLoadState: const BottleListLoadState.failed(
          'list-bottles failed',
        ),
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
        selection: KonyakHomeDetailSelection.program(
          bottle: bottle,
          program: bottle.pinnedPrograms.first,
        ),
        detailMode: BottleDetailMode.programConfiguration,
        isBottleNavigationLocked: true,
      );

      expect(switch (detailState.programConfigurationSettingsState) {
        ReadyProgramConfigurationSettings(:final settings) => settings.locale,
        LoadingProgramConfigurationSettings() => 'loading',
      }, 'ja_JP.UTF-8');
      expect(
        detailState.runtimeSettingsControlState,
        const RuntimeSettingsControlState.updating('dxvk'),
      );
      expect(
        detailState.bottleListLoadState,
        const BottleListLoadState.failed('list-bottles failed'),
      );
      expect(
        detailState.runtimeCapabilitiesState,
        const RuntimeCapabilitiesState.loading(),
      );
      expect(detailState.isBottleNavigationLocked, isTrue);
    },
  );

  test('home detail state models absent selections explicitly', () {
    final state = KonyakHomeViewState(platform: KonyakPlatform.macos);

    final detailState = state.detailStateFor(
      selection: const KonyakHomeDetailSelection.none(),
      detailMode: BottleDetailMode.overview,
      isBottleNavigationLocked: false,
    );

    expect(detailState.bottle, isNull);
    expect(detailState.selectedProgram, isNull);
    expect(
      detailState.programConfigurationSettingsState,
      isA<ReadyProgramConfigurationSettings>(),
    );
    expect(
      detailState.runtimeSettingsControlState,
      const RuntimeSettingsControlState.idle(),
    );
  });
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
