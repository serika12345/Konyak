part of '../konyak_cli.dart';

_PinnedProgramLauncherManifest? _readPinnedProgramLauncherManifest(
  String manifestPath,
) {
  try {
    return _pinnedProgramLauncherManifestFromPayload(
      File(manifestPath).readAsStringSync(),
    );
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
}
