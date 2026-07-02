import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/programs/program_configuration_settings.dart';
import 'package:konyak/src/app/programs/program_configuration_view_model.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';

void main() {
  test('models loading program configuration explicitly', () {
    final viewModel = programConfigurationViewModel(
      bottle: _bottle(id: 'steam', name: 'Steam'),
      settingsState: const ProgramConfigurationSettingsState.loading(),
      programSettingsChangeAction:
          const ProgramSettingsChangeAvailability.unavailable(),
    );

    expect(viewModel, isA<LoadingProgramConfigurationViewModel>());
  });

  test('builds ready program configuration with save availability', () {
    final viewModel = programConfigurationViewModel(
      bottle: _bottle(id: 'steam', name: 'Steam'),
      settingsState: ProgramConfigurationSettingsState.ready(
        ProgramSettingsSummary(),
      ),
      programSettingsChangeAction: ProgramSettingsChangeAvailability.available(
        (_, _, _) {},
      ),
    );

    switch (viewModel) {
      case ReadyProgramConfigurationViewModel(
        :final defaultLogPath,
        :final canSave,
      ):
        expect(defaultLogPath, '/bottles/steam/logs/latest.log');
        expect(canSave, isTrue);
      case LoadingProgramConfigurationViewModel():
        fail('Ready settings must build ready view model.');
    }
  });

  test('resolves save dispatch for current form settings', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final program = _program(name: 'Game', path: '/games/game.exe');
    final savedProgramPaths = <String>[];
    final dispatch = resolveProgramConfigurationSave(
      bottle: bottle,
      program: program,
      settings: ProgramSettingsSummary(),
      action: ProgramSettingsChangeAvailability.available(
        (_, program, _) => savedProgramPaths.add(program.path),
      ),
    );

    switch (dispatch) {
      case AvailableProgramSettingsChangeDispatch(:final invoke):
        invoke();
      case UnavailableProgramSettingsChangeDispatch():
        fail('Expected available save dispatch.');
    }

    expect(savedProgramPaths, ['/games/game.exe']);
  });
}

BottleSummary _bottle({required String id, required String name}) {
  return BottleSummary(
    id: id,
    name: name,
    path: '/bottles/$id',
    windowsVersion: 'win10',
  );
}

PinnedProgramSummary _program({required String name, required String path}) {
  return PinnedProgramSummary(name: name, path: path, removable: true);
}
