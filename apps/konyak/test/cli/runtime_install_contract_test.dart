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

  test('parses runtime install progress payloads', () {
    final progress = parseRuntimeInstallProgressPayload('''
      {
        "schemaVersion": 1,
        "runtimeInstallProgress": {
          "stage": "downloading",
          "message": "Downloading Konyak macOS Wine...",
          "fraction": 0.42
        }
      }
      ''');

    expect(progress, isNotNull);
    expect(progress!.stage, 'downloading');
    expect(progress.message, 'Downloading Konyak macOS Wine...');
    expect(progress.fraction, 0.42);
  });

  test('rejects invalid runtime install progress payloads', () {
    expect(
      parseRuntimeInstallProgressPayload(
        '{"schemaVersion":1,"runtimeInstallProgress":{"stage":"x","message":"x","fraction":1.5}}',
      ),
      isNull,
    );
  });
}
