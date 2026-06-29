import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../shared/common_helpers.dart';
import 'program_shortcut_metadata_io.dart';
import 'wine_process_metadata.dart';

Option<String> latestRunProgramPathForExecutable({
  required BottleRecord bottle,
  required String executable,
}) {
  final logFile = File(
    joinPath(bottle.path.value, const ['logs', 'latest.log']),
  );
  if (!logFile.existsSync()) {
    return const Option.none();
  }

  try {
    return latestRunProgramPathFromLog(
      bottle: bottle,
      executable: executable,
      logContents: logFile.readAsStringSync(),
    );
  } on FileSystemException {
    return const Option.none();
  }
}

Option<String> latestRunProgramPathFromLog({
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
        final hostPath = runArgumentHostPath(
          bottle: bottle,
          argument: argument,
        );
        final metadataPath = hostPath.flatMap(
          (path) => metadataProgramPathMatchingExecutable(
            bottle: bottle,
            programPath: ProgramPath(path),
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

class AsyncWineProcessHostPathResolver {
  AsyncWineProcessHostPathResolver({required this.bottle});

  final BottleRecord bottle;
  Future<String?>? latestLogContents;
  Future<Map<String, Object?>?>? launchIndex;

  Future<Option<String>> hostPath(String executable) async {
    final hostPath = wineWindowsPathToHostPath(
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

    final pinnedProgramPath = pinnedProgramPathForExecutable(
      bottle: bottle,
      executable: executable,
    );
    if (pinnedProgramPath.isSome()) {
      return pinnedProgramPath;
    }

    final recordedExternalProgramPath =
        await recordedExternalProgramPathForExecutableAsync(executable);
    if (recordedExternalProgramPath.isSome()) {
      return recordedExternalProgramPath;
    }

    return latestRunProgramPathForExecutableFromCachedLog(executable);
  }

  Future<Option<String>> recordedExternalProgramPathForExecutableAsync(
    String executable,
  ) async {
    final decoded = await (launchIndex ??= readLaunchIndex());
    if (decoded == null) {
      return const Option.none();
    }

    return recordedExternalProgramPathFromLaunchIndex(
      bottle: bottle,
      executable: executable,
      decoded: decoded,
    );
  }

  Future<Map<String, Object?>?> readLaunchIndex() async {
    final launchIndexFile = File(
      joinPath(bottle.path.value, const [
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

  Future<Option<String>> latestRunProgramPathForExecutableFromCachedLog(
    String executable,
  ) async {
    final logContents = await (latestLogContents ??= readLatestLog());
    if (logContents == null) {
      return const Option.none();
    }

    return latestRunProgramPathFromLog(
      bottle: bottle,
      executable: executable,
      logContents: logContents,
    );
  }

  Future<String?> readLatestLog() async {
    final logFile = File(
      joinPath(bottle.path.value, const ['logs', 'latest.log']),
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

Option<String> recordedExternalProgramPathForExecutable({
  required BottleRecord bottle,
  required String executable,
}) {
  final launchIndexFile = File(
    joinPath(bottle.path.value, const [
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

    return recordedExternalProgramPathFromLaunchIndex(
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

Option<String> recordedExternalProgramPathFromLaunchIndex({
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

    final metadataPath = metadataProgramPathMatchingExecutable(
      bottle: bottle,
      programPath: ProgramPath(programPath),
      executable: executable,
    );
    if (metadataPath.isNone()) {
      continue;
    }

    return metadataPath;
  }

  return const Option.none();
}

Option<String> metadataProgramPathMatchingExecutable({
  required BottleRecord bottle,
  required ProgramPath programPath,
  required String executable,
}) {
  final metadataPath = metadataProgramPath(
    bottle: bottle,
    programPath: programPath,
  );
  return executableNamesMatch(metadataPath.value, executable)
      ? Option.of(metadataPath.value)
      : const Option.none();
}
