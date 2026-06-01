part of '../konyak_cli.dart';

_PinnedProgramLauncherManifest? _readPinnedProgramLauncherManifest(
  String manifestPath,
) {
  try {
    final decoded = jsonDecode(File(manifestPath).readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final schemaVersion = decoded['schemaVersion'];
    final createdBy = decoded['createdBy'];
    final launcherId = decoded['launcherId'];
    final bottleId = decoded['bottleId'];
    final programPath = decoded['programPath'];
    final programName = decoded['programName'];
    if (schemaVersion != cliSchemaVersion ||
        createdBy != konyakMacosBundleIdentifier ||
        launcherId is! String ||
        launcherId.trim().isEmpty ||
        bottleId is! String ||
        bottleId.trim().isEmpty ||
        programPath is! String ||
        programPath.trim().isEmpty ||
        programName is! String ||
        programName.trim().isEmpty) {
      return null;
    }

    return _PinnedProgramLauncherManifest(
      launcherId: launcherId,
      bottleId: bottleId,
      programPath: programPath,
      programName: programName,
    );
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
}
