import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/konyak_cli_process_runner.dart';
import 'package:konyak/src/home_loader/home_loader_platform_helpers.dart';

void main() {
  test('models macOS native menu localization cache explicitly', () {
    const emptyCache = MacosNativeMenuLocalizationCache.empty();
    const payload = <String, String>{'settings': 'Settings'};
    final synchronizedCache = synchronizedMacosNativeMenuLocalizationCache(
      payload,
    );

    expect(
      macosNativeMenuLocalizationNeedsSync(cache: emptyCache, payload: payload),
      isTrue,
    );
    expect(
      macosNativeMenuLocalizationNeedsSync(
        cache: synchronizedCache,
        payload: payload,
      ),
      isFalse,
    );
    expect(
      macosNativeMenuLocalizationNeedsSync(
        cache: synchronizedCache,
        payload: const <String, String>{'settings': 'Preferences'},
      ),
      isTrue,
    );
  });

  test('snapshots macOS native menu localization cache payloads', () {
    final mutablePayload = <String, String>{'settings': 'Settings'};
    final synchronizedCache = synchronizedMacosNativeMenuLocalizationCache(
      mutablePayload,
    );

    mutablePayload['settings'] = 'Preferences';

    expect(
      macosNativeMenuLocalizationNeedsSync(
        cache: synchronizedCache,
        payload: const <String, String>{'settings': 'Settings'},
      ),
      isFalse,
    );
    expect(
      macosNativeMenuLocalizationNeedsSync(
        cache: synchronizedCache,
        payload: mutablePayload,
      ),
      isTrue,
    );
  });

  test('models non-list executable-open channel payloads explicitly', () {
    expect(switch (executableOpenPathsChannelPayloadFrom(null)) {
      InvalidExecutableOpenPathsChannelPayload(:final reason) => reason,
      ValidExecutableOpenPathsChannelPayload() => '',
      PartialExecutableOpenPathsChannelPayload() => '',
    }, 'expected a List<String> executable-open payload');
  });

  test('models mixed executable-open channel payloads explicitly', () {
    switch (executableOpenPathsChannelPayloadFrom(<Object?>[
      '/games/setup.exe',
      1,
    ])) {
      case PartialExecutableOpenPathsChannelPayload(
        :final paths,
        :final invalidItemCount,
      ):
        expect(paths, const <String>['/games/setup.exe']);
        expect(invalidItemCount, 1);
      case ValidExecutableOpenPathsChannelPayload() ||
          InvalidExecutableOpenPathsChannelPayload():
        fail('expected partial executable-open channel payload');
    }
  });

  test('parses valid executable-open channel payload paths', () {
    expect(
      switch (executableOpenPathsChannelPayloadFrom(<Object?>[
        ' /games/setup.EXE ',
        '/games/readme.txt',
        '',
      ])) {
        ValidExecutableOpenPathsChannelPayload(:final paths) => paths,
        PartialExecutableOpenPathsChannelPayload(:final paths) => paths,
        InvalidExecutableOpenPathsChannelPayload() => const <String>[],
      },
      const <String>['/games/setup.EXE'],
    );
  });

  test('uses machine-readable install GPTK error messages', () {
    final message = installGptkFailureMessage(
      const ProcessRunResult(
        exitCode: 1,
        stdout: '''
          {
            "schemaVersion": 1,
            "error": {
              "message": "D3DMetal.framework is missing."
            }
          }
        ''',
        stderr: 'ignored diagnostic',
      ),
      command: 'install-gptk-wine',
    );

    expect(message, 'D3DMetal.framework is missing.');
  });

  test('falls back to diagnostics when open URL has no JSON error message', () {
    final message = openUrlFailureMessage(
      const ProcessRunResult(
        exitCode: 1,
        stdout: '''
          {
            "schemaVersion": 1,
            "error": {
              "message": ""
            }
          }
        ''',
        stderr: 'network is offline',
      ),
    );

    expect(message, 'open-url failed with exit code 1: network is offline');
  });
}
