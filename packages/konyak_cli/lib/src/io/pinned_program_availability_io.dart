part of '../../konyak_cli.dart';

bool _isPinnedProgramFileAvailable({
  required BottleRecord bottle,
  required PinnedProgramRecord program,
}) {
  if (!File(program.path).existsSync()) {
    return false;
  }

  if (!_isShortcutPath(program.path)) {
    return true;
  }

  return _shortcutTargetProgramPath(
    bottle: bottle,
    shortcutPath: program.path,
  ).match(() => true, (targetPath) => File(targetPath).existsSync());
}
