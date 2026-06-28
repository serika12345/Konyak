import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/program/program_mutation_models.dart';
import 'macos_pinned_launcher_manifests.dart';

Option<PinnedProgramLauncherManifest> readPinnedProgramLauncherManifest(
  String manifestPath,
) {
  try {
    return pinnedProgramLauncherManifestFromPayload(
      File(manifestPath).readAsStringSync(),
    );
  } on FileSystemException {
    return const Option.none();
  } on FormatException {
    return const Option.none();
  }
}
