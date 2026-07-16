import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/program_settings_models.dart';
import '../domain/shared/domain_value_objects.dart';

Option<ProgramWorkingDirectoryPath> missingCustomProgramWorkingDirectory({
  required BottleRecord bottle,
  required ProgramWorkingDirectorySetting setting,
}) {
  return switch (setting) {
    ExecutableDirectoryProgramWorkingDirectorySetting() => const Option.none(),
    CustomProgramWorkingDirectorySetting() =>
      resolveProgramWorkingDirectory(
        bottle: bottle,
        executableHostPath: ProgramPath(bottle.path.value),
        setting: setting,
      ).flatMap(
        (path) => Directory(path.value).existsSync()
            ? const Option.none()
            : Option.of(path),
      ),
  };
}
