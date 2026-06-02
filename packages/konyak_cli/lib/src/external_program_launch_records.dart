part of '../konyak_cli.dart';

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

List<Map<String, Object?>>? _externalProgramLaunchEntriesFromDecoded(
  Object? decoded, {
  required String programPath,
}) {
  if (decoded is! Map<String, Object?>) {
    return null;
  }

  if (decoded['schemaVersion'] != 1) {
    return <Map<String, Object?>>[];
  }

  final launches = decoded['launches'];
  if (launches is! List<Object?>) {
    return <Map<String, Object?>>[];
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

  return entries;
}

Map<String, Object?> _externalProgramLaunchEntry(String programPath) {
  return <String, Object?>{
    'programPath': programPath,
    'executableName': _normalizedExecutableName(programPath),
  };
}

String? _externalProgramRunPath({
  required BottleRecord bottle,
  required ProgramRunRequest request,
}) {
  final normalizedProgramPath = request.programPath.trim();
  if (normalizedProgramPath.isEmpty ||
      !normalizedProgramPath.startsWith('/') ||
      _isPathWithinRoot(path: normalizedProgramPath, root: bottle.path)) {
    return null;
  }

  return normalizedProgramPath;
}
