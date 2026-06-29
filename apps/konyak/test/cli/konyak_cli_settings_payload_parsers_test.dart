import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/konyak_cli_settings_payload_parsers.dart';
import 'package:konyak/src/settings/app_settings_summary.dart';

void main() {
  test('parses app settings into explicit parse results', () {
    final result = parseAppSettingsSummary({
      'terminateWineProcessesOnClose': true,
      'defaultBottlePath': '/Volumes/Games/Bottles',
      'appearanceMode': 'light',
      'languageMode': 'ja',
      'automaticallyCheckForKonyakUpdates': true,
      'automaticallyCheckForWineUpdates': false,
      'automaticallyPinNewInstalledPrograms': false,
    });

    expect(result, isA<ParsedAppSettingsSummary>());
    final settings = (result as ParsedAppSettingsSummary).settings;
    expect(settings.appearanceMode, AppAppearanceMode.light);
    expect(settings.languageMode, AppLanguageMode.japanese);
  });

  test('rejects invalid app settings with explicit parse results', () {
    final result = parseAppSettingsSummary({
      'terminateWineProcessesOnClose': true,
      'defaultBottlePath': '',
      'appearanceMode': 'light',
      'languageMode': 'ja',
      'automaticallyCheckForKonyakUpdates': true,
      'automaticallyCheckForWineUpdates': false,
    });

    expect(result, isA<InvalidAppSettingsSummary>());
  });

  test('parses program settings into explicit parse results', () {
    final result = parseProgramSettingsSummary({
      'locale': 'ja_JP',
      'arguments': '--silent',
      'environment': {'WINEDEBUG': '-all'},
      'logging': {'createLogFile': true},
    });

    expect(result, isA<ParsedProgramSettingsSummary>());
    final settings = (result as ParsedProgramSettingsSummary).settings;
    expect(settings.environment.unlockView, const {'WINEDEBUG': '-all'});
    expect(settings.logging.createLogFile, isTrue);
  });

  test('rejects invalid program settings with explicit parse results', () {
    final result = parseProgramSettingsSummary({
      'locale': 'ja_JP',
      'arguments': '--silent',
      'environment': {'WINEDEBUG': 42},
      'logging': {'createLogFile': true},
    });

    expect(result, isA<InvalidProgramSettingsSummary>());
  });

  test('parses missing logging settings as defaults', () {
    final result = parseProgramLoggingSettingsSummary(null);

    expect(result, isA<ParsedProgramLoggingSettingsSummary>());
    final logging = (result as ParsedProgramLoggingSettingsSummary).logging;
    expect(logging.createLogFile, isTrue);
    expect(logging.additionalWineLoggingChannels, isEmpty);
  });

  test('rejects invalid string maps with explicit parse results', () {
    final result = parseStringMap({'WINEDEBUG': 42});

    expect(result, isA<InvalidStringMap>());
  });
}
