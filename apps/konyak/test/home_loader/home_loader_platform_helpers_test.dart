import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/konyak_cli_process_runner.dart';
import 'package:konyak/src/home_loader/home_loader_platform_helpers.dart';

void main() {
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
