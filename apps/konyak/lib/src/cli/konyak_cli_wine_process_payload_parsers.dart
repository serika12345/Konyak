import 'dart:convert';

import 'konyak_cli_program_result_types.dart';
import 'konyak_cli_wine_process_result_types.dart';

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

    parsedProcesses.add(
      WineProcessSummary(
        bottleId: bottleId,
        processId: processId,
        executable: executable,
        hostPath: hostPath is String ? hostPath : null,
        metadata: parseProgramMetadata(process['metadata']),
      ),
    );
  }

  return LoadedWineProcesses(processes: parsedProcesses);
}

ProgramMetadataSummary? parseProgramMetadata(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! Map<String, Object?>) {
    return null;
  }

  final architecture = value['architecture'];
  final fileDescription = value['fileDescription'];
  final productName = value['productName'];
  final companyName = value['companyName'];
  final fileVersion = value['fileVersion'];
  final productVersion = value['productVersion'];
  final iconPath = value['iconPath'];

  return ProgramMetadataSummary(
    architecture: architecture is String ? architecture : null,
    fileDescription: fileDescription is String ? fileDescription : null,
    productName: productName is String ? productName : null,
    companyName: companyName is String ? companyName : null,
    fileVersion: fileVersion is String ? fileVersion : null,
    productVersion: productVersion is String ? productVersion : null,
    iconPath: iconPath is String ? iconPath : null,
  );
}
