import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import '../domain/program/program_mutation_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../shared/model_constants.dart';

Map<String, Object?> pinnedProgramLauncherManifestJson(
  PinnedProgramLauncherManifest manifest,
) {
  return <String, Object?>{
    'schemaVersion': cliSchemaVersion,
    'createdBy': konyakMacosBundleIdentifier,
    'launcherId': manifest.launcherId.value,
    'bottleId': manifest.bottleId.value,
    'programPath': manifest.programPath.value,
    'programName': manifest.programName.value,
  };
}

Option<PinnedProgramLauncherManifest> pinnedProgramLauncherManifestFromPayload(
  String payload,
) {
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
    PinnedProgramLauncherManifest(
      launcherId: ProgramLauncherId(launcherId),
      bottleId: BottleId(bottleId),
      programPath: ProgramPath(programPath),
      programName: ProgramName(programName),
    ),
  );
}
