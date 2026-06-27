part of '../../konyak_cli.dart';

Option<String> _latestRunProgramPathForExecutable({
  required BottleRecord bottle,
  required String executable,
}) {
  final logFile = File(
    _joinPath(bottle.path.value, const ['logs', 'latest.log']),
  );
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
        final metadataPath = hostPath.flatMap(
          (path) => _metadataProgramPathMatchingExecutable(
            bottle: bottle,
            programPath: path,
            executable: executable,
          ),
        );
        if (metadataPath.isNone()) {
          continue;
        }

        return metadataPath;
      }
    }
  } on FormatException {
    return const Option.none();
  }

  return const Option.none();
}

class _AsyncWineProcessHostPathResolver {
  _AsyncWineProcessHostPathResolver({required this.bottle});

  final BottleRecord bottle;
  Future<String?>? _latestLogContents;
  Future<Map<String, Object?>?>? _launchIndex;

  Future<Option<String>> hostPath(String executable) async {
    final hostPath = _wineWindowsPathToHostPath(
      bottle: bottle,
      windowsPath: executable,
    );
    if (hostPath.isSome()) {
      return hostPath;
    }

    final normalized = executable.trim();
    if (normalized.startsWith('/') && !normalized.startsWith('/_')) {
      return Option.of(normalized);
    }

    final pinnedProgramPath = _pinnedProgramPathForExecutable(
      bottle: bottle,
      executable: executable,
    );
    if (pinnedProgramPath.isSome()) {
      return pinnedProgramPath;
    }

    final recordedExternalProgramPath =
        await _recordedExternalProgramPathForExecutableAsync(executable);
    if (recordedExternalProgramPath.isSome()) {
      return recordedExternalProgramPath;
    }

    return _latestRunProgramPathForExecutableFromCachedLog(executable);
  }

  Future<Option<String>> _recordedExternalProgramPathForExecutableAsync(
    String executable,
  ) async {
    final decoded = await (_launchIndex ??= _readLaunchIndex());
    if (decoded == null) {
      return const Option.none();
    }

    return _recordedExternalProgramPathFromLaunchIndex(
      bottle: bottle,
      executable: executable,
      decoded: decoded,
    );
  }

  Future<Map<String, Object?>?> _readLaunchIndex() async {
    final launchIndexFile = File(
      _joinPath(bottle.path.value, const [
        'cache',
        'external-program-launches.json',
      ]),
    );
    if (!await launchIndexFile.exists()) {
      return null;
    }

    try {
      final decoded = jsonDecode(await launchIndexFile.readAsString());
      return decoded is Map<String, Object?> ? decoded : null;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<Option<String>> _latestRunProgramPathForExecutableFromCachedLog(
    String executable,
  ) async {
    final logContents = await (_latestLogContents ??= _readLatestLog());
    if (logContents == null) {
      return const Option.none();
    }

    return _latestRunProgramPathFromLog(
      bottle: bottle,
      executable: executable,
      logContents: logContents,
    );
  }

  Future<String?> _readLatestLog() async {
    final logFile = File(
      _joinPath(bottle.path.value, const ['logs', 'latest.log']),
    );
    if (!await logFile.exists()) {
      return null;
    }

    try {
      return await logFile.readAsString();
    } on FileSystemException {
      return null;
    }
  }
}

Option<String> _recordedExternalProgramPathForExecutable({
  required BottleRecord bottle,
  required String executable,
}) {
  final launchIndexFile = File(
    _joinPath(bottle.path.value, const [
      'cache',
      'external-program-launches.json',
    ]),
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

    final metadataPath = _metadataProgramPathMatchingExecutable(
      bottle: bottle,
      programPath: programPath,
      executable: executable,
    );
    if (metadataPath.isNone()) {
      continue;
    }

    return metadataPath;
  }

  return const Option.none();
}

Option<String> _metadataProgramPathMatchingExecutable({
  required BottleRecord bottle,
  required String programPath,
  required String executable,
}) {
  final metadataPath = _metadataProgramPath(
    bottle: bottle,
    programPath: programPath,
  );
  return _executableNamesMatch(metadataPath, executable)
      ? Option.of(metadataPath)
      : const Option.none();
}
