part of '../konyak_cli.dart';

Option<_PinnedProgramLauncherManifest>
_pinnedProgramLauncherManifestFromPayload(String payload) {
  final decoded = jsonDecode(payload);
  if (decoded is! Map<String, dynamic>) {
    return const Option.none();
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
    return const Option.none();
  }

  return Option.of(
    _PinnedProgramLauncherManifest(
      launcherId: launcherId,
      bottleId: bottleId,
      programPath: programPath,
      programName: programName,
    ),
  );
}
