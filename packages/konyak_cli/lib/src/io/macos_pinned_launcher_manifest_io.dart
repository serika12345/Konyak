part of '../../konyak_cli.dart';

Option<PinnedProgramLauncherManifest> _readPinnedProgramLauncherManifest(
  String manifestPath,
) {
  try {
    return _pinnedProgramLauncherManifestFromPayload(
      File(manifestPath).readAsStringSync(),
    );
  } on FileSystemException {
    return const Option.none();
  } on FormatException {
    return const Option.none();
  }
}
