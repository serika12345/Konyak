import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/shared/domain_value_objects.dart';
import 'program_shortcut_metadata.dart';

Option<String> shortcutTargetProgramPath({
  required BottleRecord bottle,
  required String shortcutPath,
}) {
  try {
    return shortcutTargetProgramPathFromBytes(
      bottle: bottle,
      bytes: File(shortcutPath).readAsBytesSync(),
    );
  } on FileSystemException {
    return const Option.none();
  }
}

ProgramPath metadataProgramPath({
  required BottleRecord bottle,
  required ProgramPath programPath,
}) {
  final path = programPath.value;
  if (!isShortcutPath(path)) {
    return programPath;
  }

  return shortcutTargetProgramPath(
    bottle: bottle,
    shortcutPath: path,
  ).match(() => programPath, ProgramPath.new);
}
