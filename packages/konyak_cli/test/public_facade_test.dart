import 'package:konyak_cli/konyak_cli.dart';
import 'package:test/test.dart';

void main() {
  test('package root exposes a CLI facade without src dependency types', () {
    final result = runCli(const []);

    expect(result, isA<CliResult>());
    expect(result.exitCode, 64);
  });

  test(
    'package root exposes a streaming CLI facade without src dependency types',
    () async {
      final result = await runCliStreaming(const []);

      expect(result, isA<CliResult>());
      expect(result.exitCode, 64);
    },
  );
}
