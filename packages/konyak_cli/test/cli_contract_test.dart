import 'dart:convert';
import 'dart:io';

import 'package:konyak_cli/src/shared/model_constants.dart';
import 'package:test/test.dart';

void main() {
  test('macOS runtime release references match the repository SSOT', () {
    final referenceFile = _repoFile('runtime/macos-wine-release.json');
    final reference =
        jsonDecode(referenceFile.readAsStringSync()) as Map<String, Object?>;

    expect(reference['repository'], macosWineRuntimeRepository);
    expect(reference['defaultReleaseTag'], macosWineRuntimeDefaultReleaseTag);
    expect(
      reference['sourceManifestFileName'],
      macosWineRuntimeSourceManifestFileName,
    );
    expect(
      macosWineRuntimeSourceManifestUrl,
      'https://github.com/$macosWineRuntimeRepository/releases/download/'
      '$macosWineRuntimeDefaultReleaseTag/'
      '$macosWineRuntimeSourceManifestFileName',
    );
    expect(
      macosWineRuntimeReleaseUrl,
      'https://api.github.com/repos/$macosWineRuntimeRepository/releases/latest',
    );
  });
}

File _repoFile(String relativePath) {
  final direct = File(relativePath);
  if (direct.existsSync()) {
    return direct;
  }

  final fromPackage = File('../../$relativePath');
  if (fromPackage.existsSync()) {
    return fromPackage;
  }

  return direct;
}
