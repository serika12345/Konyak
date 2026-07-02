import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'support/cli_contract_helpers.dart';

void main() {
  test('executable prints the same machine-readable contract', () async {
    final dataHome = await Directory.systemTemp.createTemp('konyak-cli-test-');

    addTearDown(() async {
      if (await dataHome.exists()) {
        await dataHome.delete(recursive: true);
      }
    });

    final process = await Process.run(
      Platform.resolvedExecutable,
      const ['run', 'bin/konyak.dart', 'list-bottles', '--json'],
      environment: {
        'KONYAK_DATA_HOME': dataHome.path,
        'KONYAK_CONFIG_HOME': joinTestPath(dataHome.path, const ['config']),
      },
    );

    expect(process.exitCode, 0);
    expect(process.stderr.toString(), isEmpty);

    final payload =
        jsonDecode(process.stdout.toString()) as Map<String, Object?>;
    expect(payload, {'schemaVersion': 1, 'bottles': <Object?>[]});
  });
}
