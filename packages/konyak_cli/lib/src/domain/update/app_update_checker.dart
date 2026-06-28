import '../program/program_runner.dart';
import '../shared/domain_helpers.dart';

bool Function(String url) appUpdateArchiveUrlPredicate(
  KonyakHostPlatform hostPlatform,
) {
  return (url) {
    return fileNameFromUrl(url).match(() => false, (fileName) {
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
