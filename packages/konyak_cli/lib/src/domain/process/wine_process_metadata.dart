part of '../../../konyak_cli.dart';

Option<String> _wineWindowsPathToHostPath({
  required BottleRecord bottle,
  required String windowsPath,
}) {
  final normalized = windowsPath.trim().replaceAll('\\', '/');
  final driveMatch = RegExp(r'^([A-Za-z]):/?(.*)$').firstMatch(normalized);
  if (driveMatch == null) {
    return normalized.startsWith('/')
        ? Option.of(normalized)
        : const Option.none();
  }

  final drive = driveMatch.group(1)?.toLowerCase();
  final path = driveMatch.group(2) ?? '';
  final parts = path
      .split('/')
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  return switch (drive) {
    'c' => Option.of(
      _joinPath(bottle.path.value, <String>['drive_c', ...parts]),
    ),
    'z' => Option.of('/${parts.join('/')}'),
    _ => const Option.none(),
  };
}

Option<String> _wineProcessHostPath({
  required BottleRecord bottle,
  required String executable,
}) {
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

  final recordedExternalProgramPath = _recordedExternalProgramPathForExecutable(
    bottle: bottle,
    executable: executable,
  );
  if (recordedExternalProgramPath.isSome()) {
    return recordedExternalProgramPath;
  }

  return _latestRunProgramPathForExecutable(
    bottle: bottle,
    executable: executable,
  );
}

Option<String> _pinnedProgramPathForExecutable({
  required BottleRecord bottle,
  required String executable,
}) {
  for (final program in bottle.pinnedPrograms) {
    final metadataPath = _metadataProgramPath(
      bottle: bottle,
      programPath: program.path.value,
    );
    if (_executableNamesMatch(metadataPath, executable)) {
      return Option.of(metadataPath);
    }
  }

  return const Option.none();
}

Option<String> _runArgumentHostPath({
  required BottleRecord bottle,
  required String argument,
}) {
  final hostPath = _wineWindowsPathToHostPath(
    bottle: bottle,
    windowsPath: argument,
  );
  if (hostPath.isSome()) {
    return hostPath;
  }

  final normalized = argument.trim();
  return normalized.startsWith('/')
      ? Option.of(normalized)
      : const Option.none();
}

bool _executableNamesMatch(String candidatePath, String executable) {
  final candidateName = _normalizedExecutableName(candidatePath);
  final executableName = _normalizedExecutableName(executable);
  return candidateName.isNotEmpty && candidateName == executableName;
}

bool _isWineInfrastructureProcess(_WinedbgProcess process) {
  return _wineInfrastructureExecutableNames.contains(
    _normalizedExecutableName(process.executable),
  );
}

const _wineInfrastructureExecutableNames = <String>{
  'conhost.exe',
  'explorer.exe',
  'plugplay.exe',
  'rpcss.exe',
  'services.exe',
  'start.exe',
  'svchost.exe',
  'winedbg.exe',
  'winedevice.exe',
  'wineboot.exe',
  'winemenubuilder.exe',
};

String _winedbgAttachProcessId(String processId) {
  final normalized = processId.trim();
  if (normalized.startsWith(RegExp('0x', caseSensitive: false))) {
    return normalized;
  }
  if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(normalized)) {
    return '0x$normalized';
  }

  return normalized;
}

String _normalizedExecutableName(String executable) {
  final quotedMatches = RegExp(
    r'''['"]([^'"]+\.exe)['"]''',
    caseSensitive: false,
  ).allMatches(executable).toList(growable: false);
  if (quotedMatches.isNotEmpty) {
    final quotedPath = quotedMatches.last.group(1)!.replaceAll('\\', '/');
    return _baseName(quotedPath).trim().toLowerCase();
  }

  final slashNormalized = executable.trim().replaceAll('\\', '/');
  final baseName = _baseName(slashNormalized).trim();
  return baseName.toLowerCase();
}

List<_WinedbgProcess> _parseWinedbgProcessList(String stdout) {
  final processes = <_WinedbgProcess>[];
  for (final rawLine in const LineSplitter().convert(stdout)) {
    final line = rawLine.trim();
    if (line.isEmpty ||
        line.startsWith('Wine-dbg>') ||
        line.toLowerCase().startsWith('pid ')) {
      continue;
    }

    final match = RegExp(
      r'^(?:[=*>\s]+)?(0x[0-9a-fA-F]+|[0-9a-fA-F]{2,})\s+\S+\s+(.+)$',
    ).firstMatch(line);
    if (match == null) {
      continue;
    }

    final processId = match.group(1);
    final executable = _unquoteWinedbgExecutable(match.group(2) ?? '');
    if (processId == null || executable.isEmpty) {
      continue;
    }

    processes.add(
      _WinedbgProcess(processId: processId, executable: executable),
    );
  }

  return List.unmodifiable(processes);
}

String _unquoteWinedbgExecutable(String value) {
  var normalized = value.trim();
  normalized = normalized.replaceFirst(RegExp(r'''^(?:\\_|/_)\s+'''), '');
  if (normalized.length >= 2) {
    final first = normalized.codeUnitAt(0);
    final last = normalized.codeUnitAt(normalized.length - 1);
    if ((first == 0x27 && last == 0x27) || (first == 0x22 && last == 0x22)) {
      normalized = normalized.substring(1, normalized.length - 1);
    }
  }

  return normalized;
}

class _WinedbgProcess {
  const _WinedbgProcess({required this.processId, required this.executable});

  final String processId;
  final String executable;
}

Option<BottleRecord> _findBottle(
  Iterable<BottleRecord> bottles,
  String bottleId,
) {
  for (final bottle in bottles) {
    if (bottle.id.value == bottleId) {
      return Option.of(bottle);
    }
  }

  return const Option.none();
}
