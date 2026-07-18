import 'dart:io';

import 'temporary_install_profile_manifest.dart';

final class DartIoTemporaryInstallProfileManifestExecutor
    implements TemporaryInstallProfileManifestExecutor {
  const DartIoTemporaryInstallProfileManifestExecutor();

  @override
  Future<TemporaryInstallProfileManifestResult<T>> execute<T>({
    required String manifestJson,
    required TemporaryInstallProfileManifestAction<T> action,
  }) async {
    try {
      final directory = await Directory.systemTemp.createTemp(
        'konyak-profile-manifest-',
      );
      try {
        final source = File('${directory.path}/profile.json');
        await source.writeAsString(manifestJson, flush: true);
        return ExecutedTemporaryInstallProfileManifest(
          await action(source.path),
        );
      } finally {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    } on FileSystemException catch (error) {
      return TemporaryInstallProfileManifestFailure(
        message: error.message,
        diagnostic: error.toString(),
      );
    }
  }
}
