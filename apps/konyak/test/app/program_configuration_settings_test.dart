import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/programs/program_configuration_settings.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';

void main() {
  test('builds program environment from non-empty names', () {
    final environment =
        programEnvironmentFromEntries(const <ProgramEnvironmentEntry>[
          ProgramEnvironmentEntry(name: '  ', value: 'ignored'),
          ProgramEnvironmentEntry(name: 'WINEDEBUG', value: '-all'),
          ProgramEnvironmentEntry(name: 'LANG', value: 'ja_JP.UTF-8'),
          ProgramEnvironmentEntry(name: 'WINEDEBUG', value: '+seh'),
        ]);

    expect(environment, <String, String>{
      'WINEDEBUG': '+seh',
      'LANG': 'ja_JP.UTF-8',
    });
  });

  test('compares program settings by final values', () {
    final left = ProgramSettingsSummary(
      locale: 'ja_JP.UTF-8',
      arguments: '-windowed',
      environment: <String, String>{'LANG': 'ja_JP.UTF-8', 'WINEDEBUG': '-all'},
    );
    final right = ProgramSettingsSummary(
      locale: 'ja_JP.UTF-8',
      arguments: '-windowed',
      environment: <String, String>{'WINEDEBUG': '-all', 'LANG': 'ja_JP.UTF-8'},
    );

    expect(sameProgramSettings(left, right), isTrue);
  });

  test('models loading program settings explicitly', () {
    final state = programConfigurationSettingsStateFromNullable(
      settings: null,
      isLoading: true,
    );

    expect(switch (state) {
      LoadingProgramConfigurationSettings() => 'loading',
      ReadyProgramConfigurationSettings() => '',
    }, 'loading');
  });

  test('models absent loaded program settings as defaults explicitly', () {
    final state = programConfigurationSettingsStateFromNullable(
      settings: null,
      isLoading: false,
    );

    expect(switch (state) {
      ReadyProgramConfigurationSettings(:final settings) => settings.arguments,
      LoadingProgramConfigurationSettings() => 'loading',
    }, '');
  });

  test('models unavailable program settings changes explicitly', () {
    final action = programSettingsChangeAvailabilityFromNullable(null);

    expect(action, isA<UnavailableProgramSettingsChangeAvailability>());
    expect(canChangeProgramSettings(action), isFalse);
  });

  test('resolves program settings changes without a nullable callback', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    const program = PinnedProgramSummary(
      name: 'Setup',
      path: '/games/setup.exe',
      removable: true,
    );
    final settings = ProgramSettingsSummary(arguments: '-windowed');
    final changedArguments = <String>[];
    final action = ProgramSettingsChangeAvailability.available(
      (_, _, settings) => changedArguments.add(settings.arguments),
    );

    final dispatch = resolveProgramSettingsChange(
      bottle: bottle,
      program: program,
      settings: settings,
      action: action,
    );

    switch (dispatch) {
      case AvailableProgramSettingsChangeDispatch(:final invoke):
        invoke();
      case UnavailableProgramSettingsChangeDispatch():
        fail('Expected program settings change dispatch to be available.');
    }

    expect(changedArguments, <String>['-windowed']);
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
