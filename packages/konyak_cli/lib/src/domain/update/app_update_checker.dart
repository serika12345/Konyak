part of '../../../konyak_cli.dart';

bool Function(String url) _appUpdateArchiveUrlPredicate(
  KonyakHostPlatform hostPlatform,
) {
  return (url) {
    return _fileNameFromUrl(url).match(() => false, (fileName) {
      final normalizedFileName = fileName.toLowerCase();
      return switch (hostPlatform) {
        KonyakHostPlatform.macos =>
          normalizedFileName.contains('-macos-') &&
              normalizedFileName.endsWith('.dmg'),
        KonyakHostPlatform.linux =>
          normalizedFileName.contains('-linux-') &&
              normalizedFileName.endsWith('.appimage'),
      };
    });
  };
}
