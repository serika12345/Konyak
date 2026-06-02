part of '../../konyak_cli.dart';

String? _shortcutTargetProgramPath({
  required BottleRecord bottle,
  required String shortcutPath,
}) {
  try {
    return _shortcutTargetProgramPathFromBytes(
      bottle: bottle,
      bytes: File(shortcutPath).readAsBytesSync(),
    );
  } on FileSystemException {
    return null;
  }
}

String _metadataProgramPath({
  required BottleRecord bottle,
  required String programPath,
}) {
  if (!_isShortcutPath(programPath)) {
    return programPath;
  }

  return _shortcutTargetProgramPath(
        bottle: bottle,
        shortcutPath: programPath,
      ) ??
      programPath;
}
