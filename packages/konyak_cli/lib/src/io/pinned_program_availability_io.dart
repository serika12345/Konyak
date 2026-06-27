part of '../../konyak_cli.dart';

bool _isPinnedProgramFileAvailable({
  required BottleRecord bottle,
  required PinnedProgramRecord program,
}) {
  if (!File(program.path.value).existsSync()) {
    return false;
  }

  if (!_isShortcutPath(program.path.value)) {
    return true;
  }

  return _shortcutTargetProgramPath(
    bottle: bottle,
    shortcutPath: program.path.value,
  ).match(() => true, (targetPath) => File(targetPath).existsSync());
}
