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

Option<String> _latestRunProgramPathFromLog({
  required BottleRecord bottle,
  required String executable,
  required String logContents,
}) {
  try {
    for (final line in const LineSplitter().convert(logContents)) {
      final argumentsJson = line.startsWith('Arguments: ')
          ? line.substring('Arguments: '.length)
          : null;
      if (argumentsJson == null) {
        continue;
      }

      final decoded = jsonDecode(argumentsJson);
      if (decoded is! List<Object?>) {
        continue;
      }

      for (final argument in decoded.whereType<String>()) {
        final hostPath = _runArgumentHostPath(
          bottle: bottle,
          argument: argument,
        );
        if (hostPath.match(
          () => true,
          (path) => !_executableNamesMatch(path, executable),
        )) {
          continue;
        }

        return hostPath.map(
          (path) => _metadataProgramPath(bottle: bottle, programPath: path),
        );
      }
    }
  } on FormatException {
    return const Option.none();
  }

  return const Option.none();
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
    final decoded = jsonDecode(launchIndexFile.readAsStringSync());
    if (decoded is! Map<String, Object?>) {
      return const Option.none();
    }

    return _recordedExternalProgramPathFromLaunchIndex(
      bottle: bottle,
      executable: executable,
      decoded: decoded,
    );
  } on FileSystemException {
    return const Option.none();
  } on FormatException {
    return const Option.none();
  }
}

Option<String> _recordedExternalProgramPathFromLaunchIndex({
  required BottleRecord bottle,
  required String executable,
  required Map<String, Object?> decoded,
}) {
  if (decoded['schemaVersion'] != 1) {
    return const Option.none();
  }

  final launches = decoded['launches'];
  if (launches is! List<Object?>) {
    return const Option.none();
  }

  for (final launch in launches.reversed) {
    if (launch is! Map<String, Object?>) {
      continue;
    }

    final programPath = launch['programPath'];
    final executableName = launch['executableName'];
    if (programPath is! String || executableName is! String) {
      continue;
    }

    if (_normalizedExecutableName(executableName) !=
        _normalizedExecutableName(executable)) {
      continue;
    }

    return Option.of(
      _metadataProgramPath(bottle: bottle, programPath: programPath),
    );
  }

  return const Option.none();
}
