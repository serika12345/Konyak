part of '../../konyak_cli.dart';

Option<String> _shortcutTargetProgramPath({
  required BottleRecord bottle,
  required String shortcutPath,
}) {
  try {
    return _shortcutTargetProgramPathFromBytes(
      bottle: bottle,
      bytes: File(shortcutPath).readAsBytesSync(),
    );
  } on FileSystemException {
    return const Option.none();
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
  ).match(() => programPath, (targetPath) => targetPath);
}
