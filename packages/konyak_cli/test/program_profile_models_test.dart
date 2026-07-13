import 'package:konyak_cli/konyak_cli.dart';
import 'package:test/test.dart';

void main() {
  test('models a validated HTTPS installer resource', () {
    final resource = InstallerResourceRecord(
      kind: 'https',
      url: 'https://downloads.example.test/Setup.exe?channel=stable',
      sha256: '0123456789abcdef' * 4,
      fileName: 'Setup.exe',
    );

    expect(resource.kind.value, 'https');
    expect(
      resource.url.value,
      'https://downloads.example.test/Setup.exe?channel=stable',
    );
    expect(resource.sha256.value, '0123456789abcdef' * 4);
    expect(resource.fileName.value, 'Setup.exe');
  });

  test('rejects unsupported installer resource kinds', () {
    expect(() => _installerResource(kind: 'http'), throwsArgumentError);
  });

  test('validates persisted profile identity values', () {
    expect(ProfileSourceId('steam.json').value, 'steam.json');
    expect(
      ProfileManifestDigest('ABCDEF0123456789' * 4).value,
      'abcdef0123456789' * 4,
    );
    expect(() => ProfileSourceId('../steam.json'), throwsArgumentError);
    expect(() => ProfileSourceId('/steam.json'), throwsArgumentError);
    expect(() => ProfileManifestDigest('not-a-digest'), throwsArgumentError);
  });

  for (final invalidUrl in <String>[
    'http://downloads.example.test/Setup.exe',
    'https:///Setup.exe',
    'https://user@downloads.example.test/Setup.exe',
    'https://downloads.example.test/Setup.exe#fragment',
  ]) {
    test('rejects invalid installer URL $invalidUrl', () {
      expect(() => _installerResource(url: invalidUrl), throwsArgumentError);
    });
  }

  for (final invalidSha256 in <String>[
    '0123456789abcdef',
    '${'0123456789abcdef' * 3}0123456789abcdeg',
  ]) {
    test('rejects invalid installer SHA-256 $invalidSha256', () {
      expect(
        () => _installerResource(sha256: invalidSha256),
        throwsArgumentError,
      );
    });
  }

  for (final invalidFileName in <String>[
    '.exe',
    'nested/Setup.exe',
    r'nested\Setup.exe',
    'Setup.zip',
  ]) {
    test('rejects invalid installer file name $invalidFileName', () {
      expect(
        () => _installerResource(fileName: invalidFileName),
        throwsArgumentError,
      );
    });
  }
}

InstallerResourceRecord _installerResource({
  String kind = 'https',
  String url = 'https://downloads.example.test/Setup.exe',
  String sha256 =
      '0123456789abcdef0123456789abcdef'
      '0123456789abcdef0123456789abcdef',
  String fileName = 'Setup.exe',
}) {
  return InstallerResourceRecord(
    kind: kind,
    url: url,
    sha256: sha256,
    fileName: fileName,
  );
}
