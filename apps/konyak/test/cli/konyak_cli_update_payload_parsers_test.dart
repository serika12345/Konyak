import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/cli_optional_fields.dart';
import 'package:konyak/src/cli/konyak_cli_update_payload_parsers.dart';

void main() {
  test('parses update checks into explicit parse results', () {
    final result = parseUpdateCheckSummary({
      'appId': 'konyak',
      'status': 'available',
      'currentVersion': '1.0.0',
      'latestVersion': '1.1.0',
      'versionUrl': 'https://example.invalid/version.json',
      'archiveUrl': 'https://example.invalid/Konyak.dmg',
    }, idKey: 'appId');

    expect(result, isA<ParsedUpdateCheckSummary>());
    final update = (result as ParsedUpdateCheckSummary).update;
    expect(update.id, 'konyak');
    expect(update.latestVersion, const CliOptionalString.present('1.1.0'));
  });

  test('models absent and explicit null update check fields distinctly', () {
    final absentResult = parseUpdateCheckSummary({
      'appId': 'konyak',
      'status': 'current',
    }, idKey: 'appId');
    final explicitNullResult = parseUpdateCheckSummary({
      'appId': 'konyak',
      'status': 'current',
      'latestVersion': null,
    }, idKey: 'appId');

    expect(absentResult, isA<ParsedUpdateCheckSummary>());
    expect(
      (absentResult as ParsedUpdateCheckSummary).update.latestVersion,
      const CliOptionalString.absent(),
    );
    expect(explicitNullResult, isA<ParsedUpdateCheckSummary>());
    expect(
      (explicitNullResult as ParsedUpdateCheckSummary).update.latestVersion,
      const CliOptionalString.explicitNull(),
    );
  });

  test('rejects invalid update checks with explicit parse results', () {
    final result = parseUpdateCheckSummary({
      'appId': 'konyak',
      'status': 'available',
      'currentVersion': 100,
    }, idKey: 'appId');

    expect(result, isA<InvalidUpdateCheckSummary>());
  });

  test('parses update installs into explicit parse results', () {
    final result = parseUpdateInstallSummary({
      'appId': 'konyak',
      'status': 'installed',
      'currentVersion': '1.0.0',
      'installedVersion': '1.1.0',
      'archiveUrl': 'https://example.invalid/Konyak.dmg',
      'installPath': '/tmp/Konyak.dmg',
    });

    expect(result, isA<ParsedUpdateInstallSummary>());
    final install = (result as ParsedUpdateInstallSummary).update;
    expect(install.id, 'konyak');
    expect(install.installedVersion, const CliOptionalString.present('1.1.0'));
  });

  test('models absent and explicit null update install fields distinctly', () {
    final absentResult = parseUpdateInstallSummary({
      'appId': 'konyak',
      'status': 'installed',
    });
    final explicitNullResult = parseUpdateInstallSummary({
      'appId': 'konyak',
      'status': 'installed',
      'installedVersion': null,
    });

    expect(absentResult, isA<ParsedUpdateInstallSummary>());
    expect(
      (absentResult as ParsedUpdateInstallSummary).update.installedVersion,
      const CliOptionalString.absent(),
    );
    expect(explicitNullResult, isA<ParsedUpdateInstallSummary>());
    expect(
      (explicitNullResult as ParsedUpdateInstallSummary)
          .update
          .installedVersion,
      const CliOptionalString.explicitNull(),
    );
  });

  test('rejects invalid update installs with explicit parse results', () {
    final result = parseUpdateInstallSummary({
      'appId': 'konyak',
      'status': 'installed',
      'installPath': 42,
    });

    expect(result, isA<InvalidUpdateInstallSummary>());
  });
}
