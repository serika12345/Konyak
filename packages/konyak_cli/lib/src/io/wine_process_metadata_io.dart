part of '../../konyak_cli.dart';

Option<String> _latestRunProgramPathForExecutable({
  required BottleRecord bottle,
  required String executable,
}) {
  final logFile = File(_joinPath(bottle.path, const ['logs', 'latest.log']));
  if (!logFile.existsSync()) {
    return const Option.none();
  }

  try {
    return _latestRunProgramPathFromLog(
      bottle: bottle,
      executable: executable,
      logContents: logFile.readAsStringSync(),
    );
  } on FileSystemException {
    return const Option.none();
  }
}

Option<String> _recordedExternalProgramPathForExecutable({
  required BottleRecord bottle,
  required String executable,
}) {
  final launchIndexFile = File(
    _joinPath(bottle.path, const ['cache', 'external-program-launches.json']),
  );
  if (!launchIndexFile.existsSync()) {
    return const Option.none();
  }

  try {
    return _recordedExternalProgramPathFromLaunchIndex(
      bottle: bottle,
      executable: executable,
      decoded:
          jsonDecode(launchIndexFile.readAsStringSync())
              as Map<String, Object?>,
    );
  } on FileSystemException {
    return const Option.none();
  } on FormatException {
    return const Option.none();
  }
}
