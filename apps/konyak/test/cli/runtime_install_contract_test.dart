import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/runtime_install_contract.dart';

void main() {
  test('parses an installed runtime payload', () {
    final result = parseRuntimeInstallPayload('''
      {
        "schemaVersion": 1,
        "runtime": {
          "id": "konyak-macos-wine",
          "name": "Konyak macOS Wine",
          "platform": "macos",
          "architecture": "x86_64",
          "runnerKind": "macosWine",
          "isBundled": false,
          "isUpdateable": true,
          "isInstalled": true,
          "applicationSupportPath": "/Users/user/Library/Application Support/Konyak",
          "libraryPath": "/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine",
          "executablePath": "/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64"
        }
      }
      ''');

    expect(result, isA<ParsedRuntimeInstall>());
    final parsed = result as ParsedRuntimeInstall;
    expect(parsed.runtime.id, 'konyak-macos-wine');
    expect(parsed.runtime.isInstalled, isTrue);
  });

  test('parses runtime install failures', () {
    final result = parseRuntimeInstallPayload('''
      {
        "schemaVersion": 1,
        "error": {
          "code": "macosWineInstallFailed",
          "message": "download failed"
        }
      }
      ''');

    expect(result, isA<RuntimeInstallCommandFailure>());
    final failure = result as RuntimeInstallCommandFailure;
    expect(failure.message, 'download failed');
  });

  test('rejects invalid runtime install payloads', () {
    final result = parseRuntimeInstallPayload('{"schemaVersion":1}');

    expect(result, isA<RuntimeInstallParseFailure>());
  });
}
