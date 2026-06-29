import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/konyak_cli_failure_messages.dart';

void main() {
  test('parses JSON error messages into explicit parse results', () {
    final result = jsonErrorMessage('''
      {
        "schemaVersion": 1,
        "error": {
          "message": "Unable to open bottle."
        }
      }
      ''');

    expect(result, isA<ParsedJsonErrorMessage>());
    expect(
      (result as ParsedJsonErrorMessage).message,
      'Unable to open bottle.',
    );
  });

  test('represents absent JSON error messages explicitly', () {
    final result = jsonErrorMessage('{"schemaVersion":1}');

    expect(result, isA<NoJsonErrorMessage>());
  });
}
