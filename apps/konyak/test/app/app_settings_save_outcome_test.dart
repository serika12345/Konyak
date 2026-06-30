import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/app_settings_save_outcome.dart';
import 'package:konyak/src/settings/app_settings_summary.dart';

void main() {
  test('models saved app settings without a nullable result', () {
    const previousSettings = AppSettingsSummary(defaultBottlePath: '/old');
    const savedSettings = AppSettingsSummary(defaultBottlePath: '/new');

    const saved = AppSettingsSaveOutcome.saved(savedSettings);
    const failed = AppSettingsSaveOutcome.failed();
    const unmounted = AppSettingsSaveOutcome.unmounted();

    expect(saved.settingsOr(previousSettings), savedSettings);
    expect(failed.settingsOr(previousSettings), previousSettings);
    expect(unmounted.settingsOr(previousSettings), previousSettings);
  });
}
