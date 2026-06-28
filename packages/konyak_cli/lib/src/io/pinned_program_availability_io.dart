import 'dart:io';

import '../domain/bottle/bottle_models.dart';
import 'program_shortcut_metadata.dart';
import 'program_shortcut_metadata_io.dart';

bool isPinnedProgramFileAvailable({
  required BottleRecord bottle,
  required PinnedProgramRecord program,
}) {
  if (!File(program.path.value).existsSync()) {
    return false;
  }

  if (!isShortcutPath(program.path.value)) {
    return true;
  }

  return shortcutTargetProgramPath(
    bottle: bottle,
    shortcutPath: program.path.value,
  ).match(() => true, (targetPath) => File(targetPath).existsSync());
}
