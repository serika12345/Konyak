import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/home_loader/app_settings_state.dart';
import 'package:konyak/src/settings/app_settings_summary.dart';

void main() {
  test('models unavailable app settings explicitly', () {
    expect(
      shouldAutomaticallyPinNewInstalledPrograms(
        const AppSettingsState.unavailable(),
      ),
      isFalse,
    );
  });

  test('reads auto-pin preferences from loaded settings', () {
    expect(
      shouldAutomaticallyPinNewInstalledPrograms(
        const AppSettingsState.loaded(
          AppSettingsSummary(
            defaultBottlePath: '/bottles',
            automaticallyPinNewInstalledPrograms: true,
          ),
        ),
      ),
      isTrue,
    );
  });
}
