part of 'konyak_cli_client.dart';

sealed class WineProcessTerminationLoadResult {
  const WineProcessTerminationLoadResult();
}

final class TerminatedWineProcesses extends WineProcessTerminationLoadResult {
  const TerminatedWineProcesses();
}

final class WineProcessTerminationLoadFailure
    extends WineProcessTerminationLoadResult {
  const WineProcessTerminationLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class WineProcessListLoadResult {
  const WineProcessListLoadResult();
}

final class LoadedWineProcesses extends WineProcessListLoadResult {
  LoadedWineProcesses({required List<WineProcessSummary> processes})
    : processes = List.unmodifiable(processes);

  final List<WineProcessSummary> processes;
}

final class WineProcessListLoadFailure extends WineProcessListLoadResult {
  const WineProcessListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

final class WineProcessSummary {
  const WineProcessSummary({
    required this.bottleId,
    required this.processId,
    required this.executable,
    this.hostPath,
    this.metadata,
  });

  final String bottleId;
  final String processId;
  final String executable;
  final String? hostPath;
  final ProgramMetadataSummary? metadata;
}
