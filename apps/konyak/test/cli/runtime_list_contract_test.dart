import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/runtime_list_contract.dart';

void main() {
  test('parses a valid empty runtime list payload', () {
    final result = parseRuntimeListPayload('{"schemaVersion":1,"runtimes":[]}');

    expect(result, isA<ParsedRuntimeList>());
    final parsed = result as ParsedRuntimeList;
    expect(parsed.runtimes, isEmpty);
  });

  test('parses valid runtime records into immutable domain values', () {
    final result = parseRuntimeListPayload('''
      {
        "schemaVersion": 1,
        "runtimes": [
          {
            "id": "wine-stable-linux-x86_64",
            "name": "Wine Stable",
            "platform": "linux",
            "architecture": "x86_64",
            "runnerKind": "wine",
            "isBundled": false,
            "isUpdateable": true,
            "distributionKind": "bootstrap",
            "isInstalled": true,
            "applicationSupportPath": "/Users/user/Library/Application Support/Konyak",
            "libraryPath": "/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine",
            "executablePath": "/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64"
          }
        ]
      }
      ''');

    expect(result, isA<ParsedRuntimeList>());
    final parsed = result as ParsedRuntimeList;
    expect(parsed.runtimes.single.id, 'wine-stable-linux-x86_64');
    expect(parsed.runtimes.single.platform, 'linux');
    expect(parsed.runtimes.single.architecture, 'x86_64');
    expect(parsed.runtimes.single.runnerKind, 'wine');
    expect(parsed.runtimes.single.isBundled, isFalse);
    expect(parsed.runtimes.single.isUpdateable, isTrue);
    expect(parsed.runtimes.single.distributionKind, 'bootstrap');
    expect(parsed.runtimes.single.isInstalled, isTrue);
    expect(
      parsed.runtimes.single.executablePath,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
    );
    expect(
      () => parsed.runtimes.add(parsed.runtimes.single),
      throwsUnsupportedError,
    );
  });

  test('parses runtime stack component status', () {
    final result = parseRuntimeListPayload('''
      {
        "schemaVersion": 1,
        "runtimes": [
          {
            "id": "konyak-macos-wine",
            "name": "Konyak macOS Wine",
            "platform": "macos",
            "architecture": "x86_64",
            "runnerKind": "macosWine",
            "isBundled": false,
            "isUpdateable": true,
            "stack": {
              "schemaVersion": 1,
              "id": "macos-konyak-runtime-stack",
              "name": "Konyak macOS runtime stack",
              "compatibilityTarget": "macos-konyak-runtime-stack",
              "isComplete": false,
              "components": [
                {
                  "id": "wine",
                  "name": "Wine",
                  "role": "windows-runner",
                  "isRequired": true,
                  "isInstalled": false,
                  "paths": ["/runtime/bin/wine64", "/runtime/bin/wineserver"],
                  "missingPaths": ["/runtime/bin/wineserver"],
                  "version": "wine-devel-11.9"
                },
                {
                  "id": "gptk-d3dmetal",
                  "name": "GPTK/D3DMetal",
                  "role": "d3d12-metal-translation",
                  "isRequired": false,
                  "isInstalled": false,
                  "paths": ["/runtime/lib/external/D3DMetal.framework"],
                  "missingPaths": ["/runtime/lib/external/D3DMetal.framework"]
                }
              ]
            }
          }
        ]
      }
      ''');

    expect(result, isA<ParsedRuntimeList>());
    final parsed = result as ParsedRuntimeList;
    final stack = parsed.runtimes.single.stack!;
    final components = stack.components;

    expect(stack.id, 'macos-konyak-runtime-stack');
    expect(stack.isComplete, isFalse);
    expect(components.first.id, 'wine');
    expect(components.first.isRequired, isTrue);
    expect(components.first.missingPaths, ['/runtime/bin/wineserver']);
    expect(components.first.version, 'wine-devel-11.9');
    expect(components.last.id, 'gptk-d3dmetal');
    expect(components.last.isRequired, isFalse);
    expect(() => components.add(components.first), throwsUnsupportedError);
  });

  test('rejects unsupported schema versions', () {
    final result = parseRuntimeListPayload('{"schemaVersion":2,"runtimes":[]}');

    expect(result, isA<RuntimeListParseFailure>());
  });

  test('rejects invalid runtime records', () {
    final result = parseRuntimeListPayload(
      '{"schemaVersion":1,"runtimes":[{"id":"missing-fields"}]}',
    );

    expect(result, isA<RuntimeListParseFailure>());
  });
}
