import 'dart:convert';

import 'konyak_cli_program_result_types.dart';
import 'konyak_cli_wine_process_result_types.dart';

sealed class ProgramMetadataParseResult {
  const ProgramMetadataParseResult();
}

final class ParsedProgramMetadata extends ProgramMetadataParseResult {
  const ParsedProgramMetadata(this.metadata);

  final ProgramMetadataSummary metadata;
}

final class NoProgramMetadata extends ProgramMetadataParseResult {
  const NoProgramMetadata();
}

final class InvalidProgramMetadata extends ProgramMetadataParseResult {
  const InvalidProgramMetadata();
}

WineProcessListLoadResult parseWineProcessListPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return WineProcessListLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const WineProcessListLoadFailure(
      exitCode: 0,
      message: 'Unsupported Wine process list payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return WineProcessListLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Wine process list failed.',
      diagnostic: '',
    );
  }

  final wineProcesses = decoded['wineProcesses'];
  if (wineProcesses is! Map<String, Object?>) {
    return const WineProcessListLoadFailure(
      exitCode: 0,
      message: 'Missing wineProcesses payload.',
      diagnostic: '',
    );
  }

  final processes = wineProcesses['processes'];
  if (processes is! List<Object?>) {
    return const WineProcessListLoadFailure(
      exitCode: 0,
      message: 'Invalid wineProcesses payload.',
      diagnostic: '',
    );
  }

  final parsedProcesses = <WineProcessSummary>[];
  for (final process in processes) {
    if (process is! Map<String, Object?>) {
      return const WineProcessListLoadFailure(
        exitCode: 0,
        message: 'Invalid Wine process record.',
        diagnostic: '',
      );
    }

    final bottleId = process['bottleId'];
    final processId = process['processId'];
    final executable = process['executable'];
    final hostPath = process['hostPath'];
    if (bottleId is! String ||
        processId is! String ||
        executable is! String ||
        (hostPath != null && hostPath is! String)) {
      return const WineProcessListLoadFailure(
        exitCode: 0,
        message: 'Invalid Wine process record.',
        diagnostic: '',
      );
    }

    switch (parseProgramMetadata(process['metadata'])) {
      case ParsedProgramMetadata(:final metadata):
        parsedProcesses.add(
          WineProcessSummary(
            bottleId: bottleId,
            processId: processId,
            executable: executable,
            hostPath: hostPath is String ? hostPath : null,
            metadata: metadata,
          ),
        );
      case NoProgramMetadata():
        parsedProcesses.add(
          WineProcessSummary(
            bottleId: bottleId,
            processId: processId,
            executable: executable,
            hostPath: hostPath is String ? hostPath : null,
          ),
        );
      case InvalidProgramMetadata():
        return const WineProcessListLoadFailure(
          exitCode: 0,
          message: 'Invalid Wine process record.',
          diagnostic: '',
        );
    }
  }

  return LoadedWineProcesses(processes: parsedProcesses);
}

ProgramMetadataParseResult parseProgramMetadata(Object? value) {
  if (value == null) {
    return const NoProgramMetadata();
  }
  if (value is! Map<String, Object?>) {
    return const InvalidProgramMetadata();
  }

  final architecture = value['architecture'];
  final fileDescription = value['fileDescription'];
  final productName = value['productName'];
  final companyName = value['companyName'];
  final fileVersion = value['fileVersion'];
  final productVersion = value['productVersion'];
  final iconPath = value['iconPath'];

  if (!_isOptionalString(architecture) ||
      !_isOptionalString(fileDescription) ||
      !_isOptionalString(productName) ||
      !_isOptionalString(companyName) ||
      !_isOptionalString(fileVersion) ||
      !_isOptionalString(productVersion) ||
      !_isOptionalString(iconPath)) {
    return const InvalidProgramMetadata();
  }

  return ParsedProgramMetadata(
    ProgramMetadataSummary(
      architecture: architecture as String?,
      fileDescription: fileDescription as String?,
      productName: productName as String?,
      companyName: companyName as String?,
      fileVersion: fileVersion as String?,
      productVersion: productVersion as String?,
      iconPath: iconPath as String?,
    ),
  );
}

bool _isOptionalString(Object? value) {
  return value == null || value is String;
}
