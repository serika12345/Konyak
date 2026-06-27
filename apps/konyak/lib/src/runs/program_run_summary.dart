class ProgramRunSummary {
  ProgramRunSummary({
    required this.bottleId,
    required this.programPath,
    required this.runnerKind,
    required this.executable,
    required List<String> argv,
    required this.logPath,
    required this.processExitCode,
    this.logFileCreated = true,
    this.workingDirectory,
  }) : argv = List.unmodifiable(argv);

  final String bottleId;
  final String programPath;
  final String runnerKind;
  final String executable;
  final String? workingDirectory;
  final List<String> argv;
  final String logPath;
  final bool logFileCreated;
  final int processExitCode;
}
