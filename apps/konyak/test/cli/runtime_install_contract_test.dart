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
          "executablePath": "/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64",
          "archiveUrl": "https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.9/wine-devel-11.9-osx64.tar.xz",
          "versionUrl": "https://api.github.com/repos/Gcenx/macOS_Wine_builds/releases/latest"
        }
      }
      ''');

    expect(result, isA<ParsedRuntimeInstall>());
    final parsed = result as ParsedRuntimeInstall;
    expect(parsed.runtime.id, 'konyak-macos-wine');
    expect(parsed.runtime.isInstalled, isTrue);
    expect(
      parsed.runtime.archiveUrl,
      'https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.9/wine-devel-11.9-osx64.tar.xz',
    );
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
