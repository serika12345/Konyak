import '../../cli/konyak_cli_client.dart';
import '../../l10n/konyak_localizations.dart';
import '../../runs/program_run_summary.dart';

String? programRunFeedback(ProgramRunLoadResult result) {
  return switch (result) {
    CompletedProgramRun(:final run) when _isSuccessfulRun(run) => null,
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

bool _isSuccessfulRun(ProgramRunSummary run) {
  return run.processExitCode == 0;
}

bool shouldRefreshBottleAfterCommand(String command) {
  return switch (command.trim().toLowerCase()) {
    'winecfg' || 'regedit' || 'control' || 'uninstaller' => true,
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

String localizedLocationLabel(
  String location,
  KonyakLocalizations localizations,
) {
  return switch (location) {
    'c-drive' => localizations.cDrive,
    'root' => localizations.bottleFolder,
    _ => location,
  };
}
