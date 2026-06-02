part of '../../konyak_cli.dart';

String? _latestRunProgramPathForExecutable({
  required BottleRecord bottle,
  required String executable,
}) {
  final logFile = File(_joinPath(bottle.path, const ['logs', 'latest.log']));
  if (!logFile.existsSync()) {
    return null;
  }

  try {
    return _latestRunProgramPathFromLog(
      bottle: bottle,
      executable: executable,
      logContents: logFile.readAsStringSync(),
    );
  } on FileSystemException {
    return null;
  }
}

String? _recordedExternalProgramPathForExecutable({
  required BottleRecord bottle,
  required String executable,
}) {
  final launchIndexFile = File(
    _joinPath(bottle.path, const ['cache', 'external-program-launches.json']),
  );
  if (!launchIndexFile.existsSync()) {
    return null;
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
    return null;
  } on FormatException {
    return null;
  }
}
