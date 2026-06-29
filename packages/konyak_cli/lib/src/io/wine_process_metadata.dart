import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../shared/common_helpers.dart';
import 'external_payload_helpers.dart';
import 'program_shortcut_metadata_io.dart';
import 'wine_process_metadata_io.dart';

Option<String> wineWindowsPathToHostPath({
  required BottleRecord bottle,
  required String windowsPath,
}) {
  final normalized = windowsPath.trim().replaceAll('\\', '/');
  return nullableOption(
    RegExp(r'^([A-Za-z]):/?(.*)$').firstMatch(normalized),
  ).match(
    () => normalized.startsWith('/')
        ? Option.of(normalized)
        : const Option.none(),
    (driveMatch) => nullableOption(driveMatch.group(1)).flatMap((rawDrive) {
      final drive = rawDrive.toLowerCase();
      final path = nullableOption(
        driveMatch.group(2),
      ).match(() => '', (value) => value);
      final parts = path
          .split('/')
          .where((part) => part.isNotEmpty)
          .toList(growable: false);

      return switch (drive) {
        'c' => Option.of(
          joinPath(bottle.path.value, <String>['drive_c', ...parts]),
        ),
        'z' => Option.of('/${parts.join('/')}'),
        _ => const Option.none(),
      };
    }),
  );
}

Option<String> wineProcessHostPath({
  required BottleRecord bottle,
  required String executable,
}) {
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

  final recordedExternalProgramPath = recordedExternalProgramPathForExecutable(
    bottle: bottle,
    executable: executable,
  );
  if (recordedExternalProgramPath.isSome()) {
    return recordedExternalProgramPath;
  }

  return latestRunProgramPathForExecutable(
    bottle: bottle,
    executable: executable,
  );
}

Option<String> pinnedProgramPathForExecutable({
  required BottleRecord bottle,
  required String executable,
}) {
  for (final program in bottle.pinnedPrograms) {
    final metadataPath = metadataProgramPath(
      bottle: bottle,
      programPath: program.path,
    );
    if (executableNamesMatch(metadataPath.value, executable)) {
      return Option.of(metadataPath.value);
    }
  }

  return const Option.none();
}

Option<String> runArgumentHostPath({
  required BottleRecord bottle,
  required String argument,
}) {
  final hostPath = wineWindowsPathToHostPath(
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

bool executableNamesMatch(String candidatePath, String executable) {
  final candidateName = normalizedExecutableName(candidatePath);
  final executableName = normalizedExecutableName(executable);
  return candidateName.isNotEmpty && candidateName == executableName;
}

bool isWineInfrastructureProcess(WinedbgProcess process) {
  return wineInfrastructureExecutableNames.contains(
    normalizedExecutableName(process.executable),
  );
}

const wineInfrastructureExecutableNames = <String>{
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

String winedbgAttachProcessId(String processId) {
  final normalized = processId.trim();
  if (normalized.startsWith(RegExp('0x', caseSensitive: false))) {
    return normalized;
  }
  if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(normalized)) {
    return '0x$normalized';
  }

  return normalized;
}

String normalizedExecutableName(String executable) {
  final quotedMatches = RegExp(
    r'''['"]([^'"]+\.exe)['"]''',
    caseSensitive: false,
  ).allMatches(executable).toList(growable: false);
  if (quotedMatches.isNotEmpty) {
    return nullableOption(quotedMatches.last.group(1)).match(
      () => normalizedExecutableNameFromRaw(executable),
      (quotedPath) =>
          baseName(quotedPath.replaceAll('\\', '/')).trim().toLowerCase(),
    );
  }

  return normalizedExecutableNameFromRaw(executable);
}

String normalizedExecutableNameFromRaw(String executable) {
  final slashNormalized = executable.trim().replaceAll('\\', '/');
  final executableBaseName = baseName(slashNormalized).trim();
  return executableBaseName.toLowerCase();
}

List<WinedbgProcess> parseWinedbgProcessList(String stdout) {
  final processes = <WinedbgProcess>[];
  for (final rawLine in const LineSplitter().convert(stdout)) {
    final line = rawLine.trim();
    if (line.isEmpty ||
        line.startsWith('Wine-dbg>') ||
        line.toLowerCase().startsWith('pid ')) {
      continue;
    }

    nullableOption(
      RegExp(
        r'^(?:[=*>\s]+)?(0x[0-9a-fA-F]+|[0-9a-fA-F]{2,})\s+\S+\s+(.+)$',
      ).firstMatch(line),
    ).flatMap(winedbgProcessFromMatch).match(() {}, processes.add);
  }

  return List.unmodifiable(processes);
}

Option<WinedbgProcess> winedbgProcessFromMatch(RegExpMatch match) {
  return nullableOption(match.group(1)).flatMap(
    (processId) => nullableOption(match.group(2))
        .map(unquoteWinedbgExecutable)
        .flatMap(
          (executable) => executable.isEmpty
              ? const Option.none()
              : Option.of(
                  WinedbgProcess(processId: processId, executable: executable),
                ),
        ),
  );
}

String unquoteWinedbgExecutable(String value) {
  final normalized = value.trim().replaceFirst(
    RegExp(r'''^(?:\\_|/_)\s+'''),
    '',
  );
  if (normalized.length >= 2) {
    final first = normalized.codeUnitAt(0);
    final last = normalized.codeUnitAt(normalized.length - 1);
    if ((first == 0x27 && last == 0x27) || (first == 0x22 && last == 0x22)) {
      return normalized.substring(1, normalized.length - 1);
    }
  }

  return normalized;
}

class WinedbgProcess {
  const WinedbgProcess({required this.processId, required this.executable});

  final String processId;
  final String executable;
}

Option<BottleRecord> findBottle(
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
