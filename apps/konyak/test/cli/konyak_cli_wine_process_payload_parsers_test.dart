import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/konyak_cli_wine_process_payload_parsers.dart';

void main() {
  test('parses program metadata into explicit parse results', () {
    final result = parseProgramMetadata({
      'architecture': 'x86_64',
      'fileDescription': 'Steam Client',
      'productName': 'Steam',
      'companyName': 'Valve',
      'fileVersion': '1.2.3',
      'productVersion': '4.5.6',
      'iconPath': '/tmp/steam.ico',
    });

    expect(result, isA<ParsedProgramMetadata>());
    final metadata = (result as ParsedProgramMetadata).metadata;
    expect(metadata.architecture, 'x86_64');
    expect(metadata.displayName, 'Steam Client');
  });

  test('parses absent program metadata explicitly', () {
    final result = parseProgramMetadata(null);

    expect(result, isA<NoProgramMetadata>());
  });

  test('rejects invalid program metadata with explicit parse results', () {
    final result = parseProgramMetadata({'architecture': 42});

    expect(result, isA<InvalidProgramMetadata>());
  });
}
