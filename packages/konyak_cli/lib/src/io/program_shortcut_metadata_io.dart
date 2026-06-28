import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
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

String metadataProgramPath({
  required BottleRecord bottle,
  required String programPath,
}) {
  if (!isShortcutPath(programPath)) {
    return programPath;
  }

  return shortcutTargetProgramPath(
    bottle: bottle,
    shortcutPath: programPath,
  ).match(() => programPath, (targetPath) => targetPath);
}
