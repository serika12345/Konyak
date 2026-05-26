import '../../cli/konyak_cli_client.dart';
import '../../runs/program_run_summary.dart';

String? programRunFeedback(ProgramRunLoadResult result) {
  return switch (result) {
    CompletedProgramRun(:final run) when _isQuietSuccessfulWineRun(run) => null,
    CompletedProgramRun(:final run) =>
      '${run.runnerKind} exited with code ${run.processExitCode}',
    FailedProgramRun(:final message, :final runnerKind, :final executable) =>
      programRunFailureFeedback(
        message: message,
        runnerKind: runnerKind,
        executable: executable,
      ),
    UnsupportedProgramRun(:final message) ||
    MissingProgramRunBottle(:final message) ||
    ProgramRunLoadFailure(:final message) => message,
  };
}

bool _isQuietSuccessfulWineRun(ProgramRunSummary run) {
  return run.processExitCode == 0 && _isWineRunnerKind(run.runnerKind);
}

bool _isWineRunnerKind(String runnerKind) {
  final normalizedRunnerKind = runnerKind.toLowerCase();
  return normalizedRunnerKind.contains('wine') ||
      normalizedRunnerKind.contains('winetricks');
}

bool shouldRefreshBottleAfterCommand(String command) {
  return switch (command.trim().toLowerCase()) {
    'winecfg' || 'regedit' || 'control' => true,
    _ => false,
  };
}

String programRunFailureFeedback({
  required String message,
  required String runnerKind,
  required String executable,
}) {
  return '$message ($runnerKind: $executable)';
}

String locationLabel(String location) {
  return switch (location) {
    'c-drive' => 'C drive',
    'root' => 'bottle folder',
    _ => location,
  };
}
