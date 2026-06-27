part of '../../../konyak_cli.dart';

Map<String, Object?> _externalProgramLaunchIndexPayload({
  required Iterable<Map<String, Object?>> existingEntries,
  required String programPath,
}) {
  return <String, Object?>{
    'schemaVersion': 1,
    'launches': <Map<String, Object?>>[
      ...existingEntries.take(31),
      _externalProgramLaunchEntry(programPath),
    ],
  };
}

Option<List<Map<String, Object?>>> _externalProgramLaunchEntriesFromDecoded(
  Object? decoded, {
  required String programPath,
}) {
  if (decoded is! Map<String, Object?>) {
    return const Option.none();
  }

  if (decoded['schemaVersion'] != 1) {
    return Option.of(const <Map<String, Object?>>[]);
  }

  final launches = decoded['launches'];
  if (launches is! List<Object?>) {
    return Option.of(const <Map<String, Object?>>[]);
  }

  final entry = _externalProgramLaunchEntry(programPath);
  final entries = <Map<String, Object?>>[];
  for (final launch in launches) {
    if (launch is! Map<String, Object?>) {
      continue;
    }

    final existingProgramPath = launch['programPath'];
    final existingExecutableName = launch['executableName'];
    if (existingProgramPath is! String || existingExecutableName is! String) {
      continue;
    }

    if (_normalizeFilesystemPath(existingProgramPath) ==
            _normalizeFilesystemPath(programPath) &&
        _normalizedExecutableName(existingExecutableName) ==
            entry['executableName']) {
      continue;
    }

    entries.add(<String, Object?>{
      'programPath': existingProgramPath,
      'executableName': existingExecutableName,
    });
  }

  return Option.of(List.unmodifiable(entries));
}

Map<String, Object?> _externalProgramLaunchEntry(String programPath) {
  return <String, Object?>{
    'programPath': programPath,
    'executableName': _normalizedExecutableName(programPath),
  };
}

Option<String> _externalProgramRunPath({
  required BottleRecord bottle,
  required ProgramRunRequest request,
}) {
  final normalizedProgramPath = request.programPath.value.trim();
  if (normalizedProgramPath.isEmpty ||
      !normalizedProgramPath.startsWith('/') ||
      _isPathWithinRoot(path: normalizedProgramPath, root: bottle.path.value)) {
    return const Option.none();
  }

  return Option.of(normalizedProgramPath);
}
